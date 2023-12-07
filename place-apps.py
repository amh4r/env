#!python

import dataclasses
import subprocess
import typing
import threading


@dataclasses.dataclass
class Coordinates:
    x: int
    y: int


@dataclasses.dataclass
class Size:
    height: int
    width: int


class BottomScreen:
    position = Coordinates(x=0, y=0)
    size = Size(height=1080, width=1920, )


class LeftScreen:
    bottom_position = Coordinates(x=-1898, y=-468)
    half_size = Size(height=948, width=1080)


class RightScreen:
    bottom_position = Coordinates(x=2622, y=-468)
    half_size = Size(height=948, width=1080)
    top_position = Coordinates(x=2622, y=-1415)


class TopScreen:
    position = Coordinates(x=-818, y=-1415)
    size = Size(height=1440, width=3440)


screen_to_position = {
    "bottom": BottomScreen.position,
    "left.bottom": LeftScreen.bottom_position,
    "right.bottom": RightScreen.bottom_position,
    "right.top": RightScreen.top_position,
    "top": TopScreen.position,
}

screen_to_size = {
    "bottom": BottomScreen.size,
    "left.bottom": LeftScreen.half_size,
    "right.bottom": RightScreen.half_size,
    "right.top": RightScreen.half_size,
    "top": TopScreen.size,
}


@dataclasses.dataclass
class App:
    name: str
    screen: typing.Literal[
        "bottom",
        "left.bottom",
        "right.bottom",
        "right.top",
        "top",
    ]


apps = [
    App(name="Calendar", screen="left.bottom"),
    App(name="Chrome", screen="bottom"),
    App(name="Code", screen="top"),
    App(name="DataGrip", screen="bottom"),
    App(name="Discord", screen="bottom"),
    App(name="Firefox", screen="top"),
    App(name="Messages", screen="right.top"),
    App(name="Obsidian", screen="bottom"),
    App(name="Slack", screen="bottom"),
    App(name="Spotify", screen="right.bottom"),
]


def create_osascript(app: App) -> str:
    position = screen_to_position[app.screen]
    size = screen_to_size[app.screen]

    return f"""
        if application "{app.name}" is running then
            tell application "System Events" to tell process "{app.name}"
                repeat with i from 1 to count of windows
                    tell window i
                        set position to {{{position.x}, {position.y}}}
                        set size to {{{size.width}, {size.height}}}
                    end tell
                end repeat
            end tell
        end if
    """


def run_osascript(script: str) -> subprocess.CompletedProcess[bytes] | None:
    return subprocess.run(["osascript", "-e", script], timeout=1)


def main() -> None:
    threads = [
        threading.Thread(target=run_osascript, args=(create_osascript(app),))
        for app in apps
    ]

    for thread in threads:
        thread.start()

    for thread in threads:
        thread.join()


main()
