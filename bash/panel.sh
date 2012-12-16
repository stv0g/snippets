#!/bin/bash

if [ `gconftool --get /apps/panel/toplevels/bottom_panel_screen0/monitor` == 1 ]; then
        gconftool --type int --set /apps/panel/toplevels/bottom_panel_screen0/monitor 0
else
        gconftool --type int --set /apps/panel/toplevels/bottom_panel_screen0/monitor 1
fi

if [ `gconftool --get /apps/panel/toplevels/top_panel_screen0/monitor` == 1 ]; then
	gconftool --type int --set /apps/panel/toplevels/top_panel_screen0/monitor 0
else
	gconftool --type int --set /apps/panel/toplevels/top_panel_screen0/monitor 1
fi

if [ `gconftool --get /apps/panel/toplevels/panel_0/monitor` == 1 ]; then
	gconftool --type int --set /apps/panel/toplevels/panel_0/monitor 0
else
	gconftool --type int --set /apps/panel/toplevels/panel_0/monitor 1
fi
