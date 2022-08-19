import os
from setuptools import setup, find_packages

def read(fname):
    return open(os.path.join(os.path.dirname(__file__), fname)).read()

setup(
    name = 'accelerated_stats',
    version = '0.1.0',
    author = 'Steffen Vogel',
    author_email = 'post@steffenvogel.de',
    description = ('Fetch and export status and bandwidth '
                   'for servers hosted by Accelerated'),
    license = 'GPL-3.0',
    keywords = 'accelerated promtheus exporter',
    url = 'http://packages.python.org/an_example_pypi_project',
    packages=find_packages(),
    long_description=read('README'),
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Topic :: Utilities',
        'License :: OSI Approved :: BSD License',
    ],
    install_requires=[
        'pint',
        'flask',
        'requests',
        'lxml'
    ],
    entry_points={
        'console_scripts': [
            'accelerated_stats = accelerated_stats.stats:main',
            'accelerated_exporter = accelerated_stats.exporter:main',
        ]
    }
)
