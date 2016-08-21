using Gtk;
using WebKit;

struct Word {
  public string word;
  public uint32 offset;
  public uint32 size;
}

int64 binsearch(Word[] haystack, string needle) {
  int64 l = 0, r = haystack.length;
  while (r - l > 1) {
    int64 m = (l + r) / 2;
    if (haystack[m].word == needle) { return m; }
    if (haystack[m].word < needle) { l = m; } else { r = m; }
  }
  return -1;
}

public class Dictionary : Window {

    private const string TITLE = "Vala dictionary";
    private string INDEX = GLib.Environment.get_variable("HOME") + "/.dicts/En_Ru/LingvoUniversalEnRu/LingvoUniversalEnRu.idx";
    private string DICT = GLib.Environment.get_variable("HOME") +"/.dicts/En_Ru/LingvoUniversalEnRu/LingvoUniversalEnRu.dict";

    private Word[] index = {};

    private Entry word;
    private WebView article;

    public Dictionary () {
        this.title = Dictionary.TITLE;
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
        var ind = binsearch(this.index, w);
        if (ind >= 0) {
          this.article.load_html (get_article(this.index[ind].offset, this.index[ind].size), null);
        } else {
          this.article.load_html ("<i>Нет такого слова</i>", null);
        }
    }

    private string get_article (uint32 offset, uint32 size) {
        var file = File.new_for_path(DICT);
        var file_stream = file.read ();
        var data_stream = new DataInputStream (file_stream);
        data_stream.set_byte_order (DataStreamByteOrder.BIG_ENDIAN);
        data_stream.skip(offset);
        return (string) data_stream.read_bytes(size).get_data();
    }

    public void start () {
        var file = File.new_for_path(INDEX);
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
          index += Word() {word = word_str, offset = word_data_offset, size = word_data_size};
        }
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        var dictionary = new Dictionary ();

        dictionary.show_all ();
        dictionary.start ();
        Gtk.main ();

        return 0;
    }
}
