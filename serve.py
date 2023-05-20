import http.server, socketserver, sys, os
os.chdir(sys.argv[0][:sys.argv[0].rfind(os.path.sep)])
socketserver.TCPServer(("", 80), http.server.SimpleHTTPRequestHandler).serve_forever()