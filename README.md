# Music Player for watchOS 9+

- A standalone music player that syncs music files from a web server 
- Supported formats: mp3, aac/alac, wav
- Basic UI with playback control and Album Art. To be improved. 

See [TODO](/MusicPlayer%20Watch%20App/TODO.md)

# Transport music from Computers to watch
- The simplest way is to use a web server. I found python is the easiest to setup.
    - You can either in command-line, get to the directory that needs to be shared, type 
        ```
        python3 -c "import http.server, socketserver; socketserver.TCPServer(("", 80), http.server.SimpleHTTPRequestHandler).serve_forever()"
        ```
    - Or with your system file manager (explorer.exe/finder/nautilus ...), drag `serve.py` to the music directory and double-click to run it.
    - I found this to be the easiest way to start a file server. Since it works in most operating systems and there isn't external dependency except python.
## Background and Intentions
See [billsun.dev](https://billsun.dev/blog/swift.html)
