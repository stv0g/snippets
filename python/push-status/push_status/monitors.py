import os
import logging
from typing import Optional
from pathlib import Path
from retry import retry

from diskcache import Cache
from uptime_kuma_api import UptimeKumaApi, MonitorType
from uptime_kuma_api.exceptions import UptimeKumaException

cache_dir = os.environ.get("XDG_CACHE_HOME")
if cache_dir is None:
    cache_dir = Path.home() / ".cache"
else:
    cache_dir = Path(cache_dir)

cache = Cache(directory=cache_dir / "uptime_kuma")


@cache.memoize('monitors', expire=60*60*24, ignore=(2,))
@retry(tries=6, exceptions=UptimeKumaException)
def get(url: str, username: str, password: str):
    logging.debug("Fetching monitors from: %s with user %s...", url, username)

    with UptimeKumaApi(url) as api:
        api.login(username, password)

        monitors = api.get_monitors()

        logging.debug("Found %d monitors", len(monitors))

        return monitors


def get_systemd(url, username, password, host, unit) -> Optional[dict]:
    monitors = get(url, username, password)
    for monitor in monitors:
        if monitor.get('type') != MonitorType.PUSH:
            continue

        if not monitor.get('active'):
            continue

        u = None
        h = None

        for tag in monitor.get('tags', []):
            if tag.get('name') == 'systemd-unit' and tag.get('value'):
                u = tag.get('value')

            if tag.get('name') == 'host' and tag.get('value'):
                h = tag.get('value')

        if unit != u or host != h:
            continue

        return UnitMonitor(
            name=monitor.get('name'),
            token=monitor.get('pushToken'),
        )
