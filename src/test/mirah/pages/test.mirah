package "org.kaspernj.mirah.erb2mirah.generated";import org.kaspernj.mirah.erb2mirah.Page;class Erb2mirah_test_dot_mirah_dot_erb < Page;def run_code:void;self.write('<html>' + "\n" + '');
self.write('<head>' + "\n" + '');
self.write('  <title>');self.write("This is a test.");self.puts('</title>');
self.write('</head>' + "\n" + '');
self.write('<body>' + "\n" + '');
self.write('  ');
    self.puts "Weeeee!"
    self.import("org.kaspernj.mirah.erb2mirah.generated", "test_import.mirah.erb")
  self.puts('');
self.write('</body>' + "\n" + '');
self.write('</html>');
;return;end;end