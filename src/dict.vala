using Gtk;
using WebKit;

struct Word {
  public string word;
  public uint32 offset;
  public uint32 size;
  public Word(string w, uint32 o, uint32 s) {
    this.word = w;
    this.offset = o;
    this.size = s;
  }
}

Word? binsearch(Word[] haystack, string needle) {
  int64 l = 0, r = haystack.length;
  while (r - l > 1) {
    int64 m = (l + r) / 2;
    if (haystack[m].word == needle) { return haystack[m]; }
    if (haystack[m].word < needle) { l = m; } else { r = m; }
  }
  return null;
}


class Dictionary : Object {
  public string name;
  public Word[] index;
  public File dict;

  private void buildIndex(string fname) {
    var file = File.new_for_path(fname);
    var file_stream = file.read ();
    var data_stream = new DataInputStream (file_stream);
    data_stream.set_byte_order (DataStreamByteOrder.BIG_ENDIAN);
    while(true) {
      size_t len;
      uint8[] word = {};
      uint8 chr = 0;
      do {
        chr = data_stream.read_byte();
        word += chr;
      } while (chr != 0);
      string word_str = (string) word;
      uint32 word_data_offset = data_stream.read_uint32();
      uint32 word_data_size = data_stream.read_uint32();
      this.index += Word(word_str, word_data_offset, word_data_size);
    }
  }

  public string search(string word) {
    var data = binsearch(this.index, word);
    if (data == null) {return "";}
    var file_stream = this.dict.read ();
    var data_stream = new DataInputStream (file_stream);
    data_stream.set_byte_order (DataStreamByteOrder.BIG_ENDIAN);
    data_stream.skip(data.offset);
    return (string) data_stream.read_bytes(data.size).get_data();
  }

  public Dictionary(string basedir) {
    var dir = File.new_for_path(basedir);
    var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);

    FileInfo file_info;
    while ((file_info = enumerator.next_file ()) != null) {
        var fname = file_info.get_name ();
             if (fname.has_suffix(".idx"))  {buildIndex(basedir + fname);}
        else if (fname.has_suffix(".dict")) {this.dict = File.new_for_path(basedir + fname);}
        else if (fname.has_suffix(".ifo"))  {
          var file = File.new_for_path(basedir + fname);
          FileInputStream @is = file.read ();
          DataInputStream dis = new DataInputStream (@is);
          string line;

          while ((line = dis.read_line ()) != null) {
            if (line.has_prefix("bookname")) {
              this.name = line.split("=", 2)[1];
              break;
            }
          }
        }

    }
  }
}

public class DictionaryApp : Window {

    private const string TITLE = "Dictionary";
    private string dicts_dir = GLib.Environment.get_variable("HOME") + "/.dicts/";

    private Dictionary[] dicts = {};

    private Entry word;
    private WebView article;

    public DictionaryApp () {
        this.title = DictionaryApp.TITLE;
        set_default_size (800, 600);

        create_widgets ();
        connect_signals ();
        this.word.grab_focus ();
    }

    private void create_widgets () {
        this.word = new Entry ();
        this.article = new WebView ();
        var scrolled_window = new ScrolledWindow (null, null);
        scrolled_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scrolled_window.add (this.article);
        var vbox = new VBox (false, 0);
        vbox.pack_start (this.word, false, true, 0);
        vbox.add (scrolled_window);
        add (vbox);
    }

    private void connect_signals () {
        this.destroy.connect (Gtk.main_quit);
        this.word.activate.connect (on_activate);
    }

    private void on_activate () {
        var w = this.word.text;
        var text = "";
        foreach(var d in dicts) {
          var info = d.search(w);
          if (info.length > 0) {text += info + "<br><hr><br>";}
        }
        stdout.printf("%d\n", text.length);
        if (text.length > 0) {
          this.article.load_html (text, null);
        } else {
          this.article.load_html ("<i>Нет такого слова</i>", null);
        }
    }

    public void start () {
      this.dicts += new Dictionary(dicts_dir + "/En_Ru/LingvoUniversalEnRu/");
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        var app = new DictionaryApp ();

        app.show_all ();
        app.start ();
        Gtk.main ();

        return 0;
    }
}
