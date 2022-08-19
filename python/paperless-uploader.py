from glob import glob
import os
import logging
import shutil
import time
import sys

from PyPDF2 import PdfWriter, PdfReader

from urllib.parse import urljoin

from typing import List

from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
import tempfile
import requests
from requests.auth import HTTPBasicAuth

# 1pt == 1/72th inch
# 1inch == 2.54cm
PTCM = 1 / 72 * 2.54

# You authenticate via BasicAuth or with a session id.
# We use BasicAuth here
username = os.environ.get("PAPERLESS_USERNAME")
password = os.environ.get("PAPERLESS_PASSWORD")

# Where you have Paperless installed and listening
url = os.environ.get("PAPERLESS_URL")

default_tags = set(os.environ.get("PAPERLESS_DEFAULT_TAGS", "Scan").split(","))
receipe_tags = {"Receipes", "Receipes-Small"}

receipe_trim_y = 0 # 0.5 / PTCM
receipe_width_map = {"receipes": 8.5 / PTCM, "receipes-small": 6 / PTCM}

tag_id_map = {"Scan": 38, "Steffen": 89, "Britta": 88, "Bus": 52, "Wohnen": 40}

tag_type_map = {"Receipes": "Quittung", "Receipes-small": "Quittung"}
document_type_id_map = {"Quittung": 9}

def append_suffix(filename, suffix):
    return "{0}_{2}.{1}".format(*filename.rsplit('.', 1) + [suffix])

def crop_width(in_path, new_width):
    out_path = append_suffix(in_path, 'cropped')

    with open(in_path, "rb") as in_f, open(out_path, 'wb+') as out_f:
        input = PdfReader(in_f)
        output = PdfWriter()

        numPages = input.getNumPages()

        for i in range(numPages):
            page = input.getPage(i)

            width = float(page.mediaBox.getUpperRight_x())
            height = float(page.mediaBox.getUpperRight_y())

            center = width / 2

            page.trimbox.lowerLeft = (center - new_width / 2, 0 + receipe_trim_y)
            page.trimbox.upperRight = (center + new_width / 2, height - receipe_trim_y)

            page.cropbox = page.trimbox
            page.mediabox = page.trimbox

            output.addPage(page)

        output.write(out_f)

    return out_path


def upload_file(path):
    logging.info("Uploading: %s", path)

    dir = os.path.dirname(path)
    tag = os.path.basename(dir)

    tags = {tag.title()} | default_tags
    types = {tag_type_map[tag] for tag in tags if tag in tag_type_map}

    logging.info("Tags: %s", ", ".join(tags))
    logging.info("Document types: %s", ", ".join(types))

    tag_ids = {tag_id_map[tag] for tag in tags if tag in tag_id_map}
    type_ids = {document_type_id_map[typ] for typ in types if typ in document_type_id_map}

    if len(tags & receipe_tags) > 0:
        old_path = path
        logging.info("Cropping receipe...")
        path = crop_width(path, receipe_width_map[tag])

        os.remove(old_path)


    with open(path, "rb") as f:
        title = os.path.splitext(os.path.basename(path))[0]

        response = requests.post(
            url=urljoin(url, "api/documents/post_document/"),
            data=[("tags", tag_id) for tag_id in tag_ids] +
                 [("document_type", type_id) for type_id in type_ids]+
                 [("title", title)],
            files={"document": (title, f, "application/pdf")},
            auth=HTTPBasicAuth(username, password),
            allow_redirects=False,
        )

        if response.status_code in [200, 202]:
            logging.info("Successful")

            os.remove(path)
        else:
            logging.error("Failed: %d (%s)", response.status_code, response.text)


class Handler(PatternMatchingEventHandler):
    def on_closed(self, event):
        if not event.is_directory and not event.src_path.endswith("_cropped.pdf"):
            upload_file(event.src_path)


def main():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    path = sys.argv[1] if len(sys.argv) > 1 else "."

    event_handler = Handler(["*.pdf"])

    files = glob(f"{path}/**/*.pdf", recursive=True)

    logging.info("Initial upload of: %s", files)

    for file in files:
        upload_file(file)

    observer = Observer()
    observer.schedule(event_handler, path, recursive=True)
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()

    observer.join()


if __name__ == "__main__":
    main()
