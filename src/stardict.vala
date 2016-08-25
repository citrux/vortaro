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


int compare(string s1, string s2) {
  int a = s1.ascii_casecmp(s2);
  if (a ==  0) {
    return strcmp(s1, s2);
  }
  return a;
}

Word? binsearch(Word[] haystack, string needle) {
  int64 l = 0, r = haystack.length;
  while (r > l) {
    int64 m = (l + r) / 2;
    int c = compare(haystack[m].word, needle);
    if (c == 0) {
      return haystack[m];
    }
    if (c < 0) { l = m + 1; } else { r = m; }
  }
  return null;
}


class Dictionary : Object {
  public string name;
  public Word[] index;
  public File dict;

  private void buildIndex(string fname) {
    var file = File.new_for_path(fname);
    try {
      var file_stream = file.read ();
      var data_stream = new DataInputStream (file_stream);
      data_stream.set_byte_order (DataStreamByteOrder.BIG_ENDIAN);
      while(true) {
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
    } catch {}

  }

  public string search(string word) {
    var result = "";
    var data = binsearch(this.index, word);
    if (data == null) {return "";}
    try {
      var file_stream = this.dict.read ();
      var data_stream = new DataInputStream (file_stream);
      data_stream.set_byte_order (DataStreamByteOrder.BIG_ENDIAN);
      data_stream.skip(data.offset);
      var raw = new uint8[data.size];
      data_stream.read(raw);
      raw += 0;
      result = (string) raw;
    } catch {}
    var open_tag = new Regex("<(\\w+)>");
    var close_tag = new Regex("</\\w+>");
    result = open_tag.replace(result, -1, 0, "<span class='\\1'>");
    result = close_tag.replace(result, -1, 0, "</span>");
    result = result.replace("\n","<br />");
    result = @"<div><span class='dict'>$name</span>$result</div>";
    return result;
  }

  public Dictionary(string basedir) {
    try {
      var dir = File.new_for_path(basedir);
      var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);

      FileInfo file_info;
      while ((file_info = enumerator.next_file ()) != null) {
        var path = Path.build_path(Path.DIR_SEPARATOR_S, basedir, file_info.get_name ());
        if (path.has_suffix(".idx")) {
          buildIndex(path);
        } else if (path.has_suffix(".dict")) {
          this.dict = File.new_for_path(path);
        } else if (path.has_suffix(".ifo")) {
          var file = File.new_for_path(path);
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
    } catch {}
  }
}


