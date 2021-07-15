{ pkgs ? import <nixpkgs> {}, user, token }:

pkgs.writeScriptBin "pushover" ''
  #!${pkgs.python}/bin/python

  import getopt
  import sys
  import os
  import StringIO
  import httplib
  import urllib


  class Pushover:
      priorities = {"high": 1, "normal": 0, 'low': -1}

      message = ""
      priority = priorities["normal"]
      title = ""
      token = ${token}
      url = None
      user = ${user}

      def exit(self, code):
          sys.exit(code)

      def usage(self):
          file = os.path.basename(__file__)
          print "Usage:   " + file + " [options] <message> <title>"
          print "Stdin:   " + file + " [options] - <title>"
          print "Example: " + file + " \"Hello World\""
          print ""
          print "  -p --priority <high, normal, low>   Default: normal"
          print "  -l --url      <url>                 Link the message to this URL"

      def main(self):
          try:
              opts, args = getopt.getopt(sys.argv[1:], "hu:t:p:u:c:l:",
                                        ["help",
                                          "user=",
                                          "token=",
                                          "priority=",
                                          "url="])
          except getopt.GetoptError as err:
              print str(err)
              self.usage()
              self.exit(2)

          if len(args) > 0:
              self.message = args.pop(0)

              if len(args) > 0:
                  self.title = args.pop(0)

              for o, a in opts:
                  if o in ("-h", "--help"):
                      self.usage()
                      self.exit(0)
                  elif o in ("-u", "--user"):
                      self.user = a
                  elif o in ("-t", "--token"):
                      self.token = a
                  elif o in ("-p", "--priority"):
                      for name, priority in self.priorities.iteritems():
                          if name == a:
                              self.priority = priority
                  elif o in ("-l", "--url"):
                      self.url = a

              if self.message == "-":
                  while True:
                      try:
                          line = sys.stdin.readline().strip()
                          if len(line) > 0:
                              self.message = line
                              self.send()
                      except KeyboardInterrupt:
                          break
                      if not line:
                          break

              else:
                  self.send()

          else:
              self.usage()
              self.exit(2)

      def send(self):
          conn = httplib.HTTPSConnection("api.pushover.net:443")
          conn.request("POST", "/1/messages.json",
                      urllib.urlencode({
                          "token": self.token,
                          "user": self.user,
                          "url": self.url,
                          "title": self.title,
                          "message": self.message,
                          "priority": self.priority,
                      }), {"Content-type": "application/x-www-form-urlencoded"})

  if __name__ == "__main__":
      pushover = Pushover()
      pushover.main()
''
