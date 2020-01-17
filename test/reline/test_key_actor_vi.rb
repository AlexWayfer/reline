require_relative 'helper'

class Reline::KeyActor::ViInsert::Test < Reline::TestCase
  def setup
    Reline.send(:test_mode)
    @prompt = '> '
    @config = Reline::Config.new
    @config.read_lines(<<~LINES.split(/(?<=\n)/))
      set editing-mode vi
    LINES
    @encoding = (RELINE_TEST_ENCODING rescue Encoding.default_external)
    @line_editor = Reline::LineEditor.new(@config, @encoding)
    @line_editor.reset(@prompt, encoding: @encoding)
  end

  def test_vi_command_mode
    input_keys("\C-[")
    assert_instance_of(Reline::KeyActor::ViCommand, @config.editing_mode)
  end

  def test_vi_command_mode_with_input
    input_keys("abc\C-[")
    assert_instance_of(Reline::KeyActor::ViCommand, @config.editing_mode)
    assert_line('abc')
  end

  def test_vi_insert
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
    input_keys('i')
    assert_line('i')
    assert_cursor(1)
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
    input_keys("\C-[")
    assert_line('i')
    assert_cursor(0)
    assert_instance_of(Reline::KeyActor::ViCommand, @config.editing_mode)
    input_keys('i')
    assert_line('i')
    assert_cursor(0)
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
  end

  def test_vi_add
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
    input_keys('a')
    assert_line('a')
    assert_cursor(1)
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
    input_keys("\C-[")
    assert_line('a')
    assert_cursor(0)
    assert_instance_of(Reline::KeyActor::ViCommand, @config.editing_mode)
    input_keys('a')
    assert_line('a')
    assert_cursor(1)
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
  end

  def test_vi_insert_at_bol
    input_keys('I')
    assert_line('I')
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
    input_keys("12345\C-[hh")
    assert_line('I12345')
    assert_byte_pointer_size('I12')
    assert_cursor(3)
    assert_cursor_max(6)
    assert_instance_of(Reline::KeyActor::ViCommand, @config.editing_mode)
    input_keys('I')
    assert_line('I12345')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(6)
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
  end

  def test_vi_add_at_eol
    input_keys('A')
    assert_line('A')
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
    input_keys("12345\C-[hh")
    assert_line('A12345')
    assert_byte_pointer_size('A12')
    assert_cursor(3)
    assert_cursor_max(6)
    assert_instance_of(Reline::KeyActor::ViCommand, @config.editing_mode)
    input_keys('A')
    assert_line('A12345')
    assert_byte_pointer_size('A12345')
    assert_cursor(6)
    assert_cursor_max(6)
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
  end

  def test_ed_insert_one
    input_keys('a')
    assert_line('a')
    assert_byte_pointer_size('a')
    assert_cursor(1)
    assert_cursor_max(1)
  end

  def test_ed_insert_two
    input_keys('ab')
    assert_line('ab')
    assert_byte_pointer_size('ab')
    assert_cursor(2)
    assert_cursor_max(2)
  end

  def test_ed_insert_mbchar_one
    input_keys('か')
    assert_line('か')
    assert_byte_pointer_size('か')
    assert_cursor(2)
    assert_cursor_max(2)
  end

  def test_ed_insert_mbchar_two
    input_keys('かき')
    assert_line('かき')
    assert_byte_pointer_size('かき')
    assert_cursor(4)
    assert_cursor_max(4)
  end

  def test_ed_insert_for_mbchar_by_plural_code_points
    input_keys("か\u3099")
    assert_line("か\u3099")
    assert_byte_pointer_size("か\u3099")
    assert_cursor(2)
    assert_cursor_max(2)
  end

  def test_ed_insert_for_plural_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099")
    assert_line("か\u3099き\u3099")
    assert_byte_pointer_size("か\u3099き\u3099")
    assert_cursor(4)
    assert_cursor_max(4)
  end

  def test_ed_next_char
    input_keys("abcdef\C-[0")
    assert_line('abcdef')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(6)
    input_keys('l')
    assert_line('abcdef')
    assert_byte_pointer_size('a')
    assert_cursor(1)
    assert_cursor_max(6)
    input_keys('2l')
    assert_line('abcdef')
    assert_byte_pointer_size('abc')
    assert_cursor(3)
    assert_cursor_max(6)
  end

  def test_ed_prev_char
    input_keys("abcdef\C-[")
    assert_line('abcdef')
    assert_byte_pointer_size('abcde')
    assert_cursor(5)
    assert_cursor_max(6)
    input_keys('h')
    assert_line('abcdef')
    assert_byte_pointer_size('abcd')
    assert_cursor(4)
    assert_cursor_max(6)
    input_keys('2h')
    assert_line('abcdef')
    assert_byte_pointer_size('ab')
    assert_cursor(2)
    assert_cursor_max(6)
  end

  def test_history
    Reline::HISTORY.concat(%w{abc 123 AAA})
    input_keys("\C-[")
    assert_line('')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    input_keys('k')
    assert_line('AAA')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(3)
    input_keys('2k')
    assert_line('abc')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(3)
    input_keys('j')
    assert_line('123')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(3)
    input_keys('2j')
    assert_line('')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
  end

  def test_vi_paste_prev
    input_keys("abcde\C-[3h")
    assert_line('abcde')
    assert_byte_pointer_size('a')
    assert_cursor(1)
    assert_cursor_max(5)
    input_keys('P')
    assert_line('abcde')
    assert_byte_pointer_size('a')
    assert_cursor(1)
    assert_cursor_max(5)
    input_keys('d$')
    assert_line('a')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(1)
    input_keys('P')
    assert_line('bcdea')
    assert_byte_pointer_size('bcd')
    assert_cursor(3)
    assert_cursor_max(5)
    input_keys('2P')
    assert_line('bcdbcdbcdeeea')
    assert_byte_pointer_size('bcdbcdbcd')
    assert_cursor(9)
    assert_cursor_max(13)
  end

  def test_vi_paste_next
    input_keys("abcde\C-[3h")
    assert_line('abcde')
    assert_byte_pointer_size('a')
    assert_cursor(1)
    assert_cursor_max(5)
    input_keys('p')
    assert_line('abcde')
    assert_byte_pointer_size('a')
    assert_cursor(1)
    assert_cursor_max(5)
    input_keys('d$')
    assert_line('a')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(1)
    input_keys('p')
    assert_line('abcde')
    assert_byte_pointer_size('abcd')
    assert_cursor(4)
    assert_cursor_max(5)
    input_keys('2p')
    assert_line('abcdebcdebcde')
    assert_byte_pointer_size('abcdebcdebcd')
    assert_cursor(12)
    assert_cursor_max(13)
  end

  def test_vi_paste_prev_for_mbchar
    input_keys("あいうえお\C-[3h")
    assert_line('あいうえお')
    assert_byte_pointer_size('あ')
    assert_cursor(2)
    assert_cursor_max(10)
    input_keys('P')
    assert_line('あいうえお')
    assert_byte_pointer_size('あ')
    assert_cursor(2)
    assert_cursor_max(10)
    input_keys('d$')
    assert_line('あ')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(2)
    input_keys('P')
    assert_line('いうえおあ')
    assert_byte_pointer_size('いうえ')
    assert_cursor(6)
    assert_cursor_max(10)
    input_keys('2P')
    assert_line('いうえいうえいうえおおおあ')
    assert_byte_pointer_size('いうえいうえいうえ')
    assert_cursor(18)
    assert_cursor_max(26)
  end

  def test_vi_paste_next_for_mbchar
    input_keys("あいうえお\C-[3h")
    assert_line('あいうえお')
    assert_byte_pointer_size('あ')
    assert_cursor(2)
    assert_cursor_max(10)
    input_keys('p')
    assert_line('あいうえお')
    assert_byte_pointer_size('あ')
    assert_cursor(2)
    assert_cursor_max(10)
    input_keys('d$')
    assert_line('あ')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(2)
    input_keys('p')
    assert_line('あいうえお')
    assert_byte_pointer_size('あいうえ')
    assert_cursor(8)
    assert_cursor_max(10)
    input_keys('2p')
    assert_line('あいうえおいうえおいうえお')
    assert_byte_pointer_size('あいうえおいうえおいうえ')
    assert_cursor(24)
    assert_cursor_max(26)
  end

  def test_vi_paste_prev_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099く\u3099け\u3099こ\u3099\C-[3h")
    assert_line("か\u3099き\u3099く\u3099け\u3099こ\u3099")
    assert_byte_pointer_size("か\u3099")
    assert_cursor(2)
    assert_cursor_max(10)
    input_keys('P')
    assert_line("か\u3099き\u3099く\u3099け\u3099こ\u3099")
    assert_byte_pointer_size("か\u3099")
    assert_cursor(2)
    assert_cursor_max(10)
    input_keys('d$')
    assert_line("か\u3099")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(2)
    input_keys('P')
    assert_line("き\u3099く\u3099け\u3099こ\u3099か\u3099")
    assert_byte_pointer_size("き\u3099く\u3099け\u3099")
    assert_cursor(6)
    assert_cursor_max(10)
    input_keys('2P')
    assert_line("き\u3099く\u3099け\u3099き\u3099く\u3099け\u3099き\u3099く\u3099け\u3099こ\u3099こ\u3099こ\u3099か\u3099")
    assert_byte_pointer_size("き\u3099く\u3099け\u3099き\u3099く\u3099け\u3099き\u3099く\u3099け\u3099")
    assert_cursor(18)
    assert_cursor_max(26)
  end

  def test_vi_paste_next_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099く\u3099け\u3099こ\u3099\C-[3h")
    assert_line("か\u3099き\u3099く\u3099け\u3099こ\u3099")
    assert_byte_pointer_size("か\u3099")
    assert_cursor(2)
    assert_cursor_max(10)
    input_keys('p')
    assert_line("か\u3099き\u3099く\u3099け\u3099こ\u3099")
    assert_byte_pointer_size("か\u3099")
    assert_cursor(2)
    assert_cursor_max(10)
    input_keys('d$')
    assert_line("か\u3099")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(2)
    input_keys('p')
    assert_line("か\u3099き\u3099く\u3099け\u3099こ\u3099")
    assert_byte_pointer_size("か\u3099き\u3099く\u3099け\u3099")
    assert_cursor(8)
    assert_cursor_max(10)
    input_keys('2p')
    assert_line("か\u3099き\u3099く\u3099け\u3099こ\u3099き\u3099く\u3099け\u3099こ\u3099き\u3099く\u3099け\u3099こ\u3099")
    assert_byte_pointer_size("か\u3099き\u3099く\u3099け\u3099こ\u3099き\u3099く\u3099け\u3099こ\u3099き\u3099く\u3099け\u3099")
    assert_cursor(24)
    assert_cursor_max(26)
  end

  def test_vi_prev_next_word
    input_keys("aaa b{b}b ccc\C-[0")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa ')
    assert_cursor(4)
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa b')
    assert_cursor(5)
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa b{')
    assert_cursor(6)
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa b{b')
    assert_cursor(7)
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa b{b}')
    assert_cursor(8)
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa b{b}b ')
    assert_cursor(10)
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa b{b}b cc')
    assert_cursor(12)
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('aaa b{b}b ')
    assert_cursor(10)
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('aaa b{b}')
    assert_cursor(8)
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('aaa b{b')
    assert_cursor(7)
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('aaa b{')
    assert_cursor(6)
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('aaa b')
    assert_cursor(5)
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('aaa ')
    assert_cursor(4)
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(13)
    input_keys('3w')
    assert_byte_pointer_size('aaa b{')
    assert_cursor(6)
    assert_cursor_max(13)
    input_keys('3w')
    assert_byte_pointer_size('aaa b{b}b ')
    assert_cursor(10)
    assert_cursor_max(13)
    input_keys('3w')
    assert_byte_pointer_size('aaa b{b}b cc')
    assert_cursor(12)
    assert_cursor_max(13)
    input_keys('3b')
    assert_byte_pointer_size('aaa b{b')
    assert_cursor(7)
    assert_cursor_max(13)
    input_keys('3b')
    assert_byte_pointer_size('aaa ')
    assert_cursor(4)
    assert_cursor_max(13)
    input_keys('3b')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(13)
  end

  def test_vi_end_word
    input_keys("aaa   b{b}}}b   ccc\C-[0")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aa')
    assert_cursor(2)
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   ')
    assert_cursor(6)
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   b')
    assert_cursor(7)
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   b{')
    assert_cursor(8)
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   b{b}}')
    assert_cursor(11)
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   b{b}}}')
    assert_cursor(12)
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   b{b}}}b   cc')
    assert_cursor(18)
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   b{b}}}b   cc')
    assert_cursor(18)
    assert_cursor_max(19)
    input_keys('03e')
    assert_byte_pointer_size('aaa   b')
    assert_cursor(7)
    assert_cursor_max(19)
    input_keys('3e')
    assert_byte_pointer_size('aaa   b{b}}}')
    assert_cursor(12)
    assert_cursor_max(19)
    input_keys('3e')
    assert_byte_pointer_size('aaa   b{b}}}b   cc')
    assert_cursor(18)
    assert_cursor_max(19)
  end

  def test_vi_prev_next_big_word
    input_keys("aaa b{b}b ccc\C-[0")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(13)
    input_keys('W')
    assert_byte_pointer_size('aaa ')
    assert_cursor(4)
    assert_cursor_max(13)
    input_keys('W')
    assert_byte_pointer_size('aaa b{b}b ')
    assert_cursor(10)
    assert_cursor_max(13)
    input_keys('W')
    assert_byte_pointer_size('aaa b{b}b cc')
    assert_cursor(12)
    assert_cursor_max(13)
    input_keys('B')
    assert_byte_pointer_size('aaa b{b}b ')
    assert_cursor(10)
    assert_cursor_max(13)
    input_keys('B')
    assert_byte_pointer_size('aaa ')
    assert_cursor(4)
    assert_cursor_max(13)
    input_keys('B')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(13)
    input_keys('2W')
    assert_byte_pointer_size('aaa b{b}b ')
    assert_cursor(10)
    assert_cursor_max(13)
    input_keys('2W')
    assert_byte_pointer_size('aaa b{b}b cc')
    assert_cursor(12)
    assert_cursor_max(13)
    input_keys('2B')
    assert_byte_pointer_size('aaa ')
    assert_cursor(4)
    assert_cursor_max(13)
    input_keys('2B')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(13)
  end

  def test_vi_end_big_word
    input_keys("aaa   b{b}}}b   ccc\C-[0")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(19)
    input_keys('E')
    assert_byte_pointer_size('aa')
    assert_cursor(2)
    assert_cursor_max(19)
    input_keys('E')
    assert_byte_pointer_size('aaa   b{b}}}')
    assert_cursor(12)
    assert_cursor_max(19)
    input_keys('E')
    assert_byte_pointer_size('aaa   b{b}}}b   cc')
    assert_cursor(18)
    assert_cursor_max(19)
    input_keys('E')
    assert_byte_pointer_size('aaa   b{b}}}b   cc')
    assert_cursor(18)
    assert_cursor_max(19)
  end

  def test_ed_quoted_insert
    input_keys("ab\C-v\C-acd")
    assert_line("ab\C-acd")
    assert_byte_pointer_size("ab\C-acd")
    assert_cursor(6)
    assert_cursor_max(6)
  end

  def test_ed_quoted_insert_with_vi_arg
    input_keys("ab\C-[3\C-v\C-aacd")
    assert_line("a\C-a\C-a\C-abcd")
    assert_byte_pointer_size("a\C-a\C-a\C-abcd")
    assert_cursor(10)
    assert_cursor_max(10)
  end

  def test_vi_replace_char
    input_keys("abcdef\C-[03l")
    assert_line('abcdef')
    assert_byte_pointer_size('abc')
    assert_cursor(3)
    assert_cursor_max(6)
    input_keys('rz')
    assert_line('abczef')
    assert_byte_pointer_size('abc')
    assert_cursor(3)
    assert_cursor_max(6)
    input_keys('2rx')
    assert_line('abcxxf')
    assert_byte_pointer_size('abcxx')
    assert_cursor(5)
    assert_cursor_max(6)
  end

  def test_vi_next_char
    input_keys("abcdef\C-[0")
    assert_line('abcdef')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(6)
    input_keys('fz')
    assert_line('abcdef')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(6)
    input_keys('fe')
    assert_line('abcdef')
    assert_byte_pointer_size('abcd')
    assert_cursor(4)
    assert_cursor_max(6)
  end

  def test_vi_to_next_char
    input_keys("abcdef\C-[0")
    assert_line('abcdef')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(6)
    input_keys('tz')
    assert_line('abcdef')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(6)
    input_keys('te')
    assert_line('abcdef')
    assert_byte_pointer_size('abc')
    assert_cursor(3)
    assert_cursor_max(6)
  end

  def test_vi_delete_next_char
    input_keys("abc\C-[h")
    assert_byte_pointer_size('a')
    assert_cursor(1)
    assert_cursor_max(3)
    assert_line('abc')
    input_keys('x')
    assert_byte_pointer_size('a')
    assert_cursor(1)
    assert_cursor_max(2)
    assert_line('ac')
    input_keys('x')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(1)
    assert_line('a')
    input_keys('x')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    assert_line('')
    input_keys('x')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    assert_line('')
  end

  def test_vi_delete_next_char_for_mbchar
    input_keys("あいう\C-[h")
    assert_byte_pointer_size('あ')
    assert_cursor(2)
    assert_cursor_max(6)
    assert_line('あいう')
    input_keys('x')
    assert_byte_pointer_size('あ')
    assert_cursor(2)
    assert_cursor_max(4)
    assert_line('あう')
    input_keys('x')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(2)
    assert_line('あ')
    input_keys('x')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    assert_line('')
    input_keys('x')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    assert_line('')
  end

  def test_vi_delete_next_char_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099く\u3099\C-[h")
    assert_byte_pointer_size("か\u3099")
    assert_cursor(2)
    assert_cursor_max(6)
    assert_line("か\u3099き\u3099く\u3099")
    input_keys('x')
    assert_byte_pointer_size("か\u3099")
    assert_cursor(2)
    assert_cursor_max(4)
    assert_line("か\u3099く\u3099")
    input_keys('x')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(2)
    assert_line("か\u3099")
    input_keys('x')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    assert_line('')
    input_keys('x')
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    assert_line('')
  end

  def test_vi_delete_prev_char
    input_keys('ab')
    assert_byte_pointer_size('ab')
    assert_cursor(2)
    assert_cursor_max(2)
    input_keys("\C-h")
    assert_byte_pointer_size('a')
    assert_cursor(1)
    assert_cursor_max(1)
    assert_line('a')
  end

  def test_vi_delete_prev_char_for_mbchar
    input_keys('かき')
    assert_byte_pointer_size('かき')
    assert_cursor(4)
    assert_cursor_max(4)
    input_keys("\C-h")
    assert_byte_pointer_size('か')
    assert_cursor(2)
    assert_cursor_max(2)
    assert_line('か')
  end

  def test_vi_delete_prev_char_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099")
    assert_byte_pointer_size("か\u3099き\u3099")
    assert_cursor(4)
    assert_cursor_max(4)
    input_keys("\C-h")
    assert_byte_pointer_size("か\u3099")
    assert_cursor(2)
    assert_cursor_max(2)
    assert_line("か\u3099")
  end

  def test_ed_delete_prev_char
    input_keys("abcdefg\C-[h")
    assert_byte_pointer_size('abcde')
    assert_cursor(5)
    assert_cursor_max(7)
    assert_line('abcdefg')
    input_keys('X')
    assert_byte_pointer_size('abcd')
    assert_cursor(4)
    assert_cursor_max(6)
    assert_line('abcdfg')
    input_keys('3X')
    assert_byte_pointer_size('a')
    assert_cursor(1)
    assert_cursor_max(3)
    assert_line('afg')
    input_keys('p')
    assert_byte_pointer_size('abcd')
    assert_cursor(4)
    assert_cursor_max(6)
    assert_line('afbcdg')
  end

  def test_ed_delete_prev_word
    input_keys('abc def{bbb}ccc')
    assert_byte_pointer_size('abc def{bbb}ccc')
    assert_cursor(15)
    assert_cursor_max(15)
    input_keys("\C-w")
    assert_byte_pointer_size('abc def{bbb}')
    assert_cursor(12)
    assert_cursor_max(12)
    assert_line('abc def{bbb}')
    input_keys("\C-w")
    assert_byte_pointer_size('abc def{')
    assert_cursor(8)
    assert_cursor_max(8)
    assert_line('abc def{')
    input_keys("\C-w")
    assert_byte_pointer_size('abc ')
    assert_cursor(4)
    assert_cursor_max(4)
    assert_line('abc ')
    input_keys("\C-w")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    assert_line('')
  end

  def test_ed_delete_prev_word_for_mbchar
    input_keys('あいう かきく{さしす}たちつ')
    assert_byte_pointer_size('あいう かきく{さしす}たちつ')
    assert_cursor(27)
    assert_cursor_max(27)
    input_keys("\C-w")
    assert_byte_pointer_size('あいう かきく{さしす}')
    assert_cursor(21)
    assert_cursor_max(21)
    assert_line('あいう かきく{さしす}')
    input_keys("\C-w")
    assert_byte_pointer_size('あいう かきく{')
    assert_cursor(14)
    assert_cursor_max(14)
    assert_line('あいう かきく{')
    input_keys("\C-w")
    assert_byte_pointer_size('あいう ')
    assert_cursor(7)
    assert_cursor_max(7)
    assert_line('あいう ')
    input_keys("\C-w")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    assert_line('')
  end

  def test_ed_delete_prev_word_for_mbchar_by_plural_code_points
    input_keys("あいう か\u3099き\u3099く\u3099{さしす}たちつ")
    assert_byte_pointer_size("あいう か\u3099き\u3099く\u3099{さしす}たちつ")
    assert_cursor(27)
    assert_cursor_max(27)
    input_keys("\C-w")
    assert_byte_pointer_size("あいう か\u3099き\u3099く\u3099{さしす}")
    assert_cursor(21)
    assert_cursor_max(21)
    assert_line("あいう か\u3099き\u3099く\u3099{さしす}")
    input_keys("\C-w")
    assert_byte_pointer_size("あいう か\u3099き\u3099く\u3099{")
    assert_cursor(14)
    assert_cursor_max(14)
    assert_line("あいう か\u3099き\u3099く\u3099{")
    input_keys("\C-w")
    assert_byte_pointer_size('あいう ')
    assert_cursor(7)
    assert_cursor_max(7)
    assert_line('あいう ')
    input_keys("\C-w")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    assert_line('')
  end

  def test_ed_newline_with_cr
    input_keys('ab')
    assert_byte_pointer_size('ab')
    assert_cursor(2)
    assert_cursor_max(2)
    refute(@line_editor.finished?)
    input_keys("\C-m")
    assert_line('ab')
    assert(@line_editor.finished?)
  end

  def test_ed_newline_with_lf
    input_keys('ab')
    assert_byte_pointer_size('ab')
    assert_cursor(2)
    assert_cursor_max(2)
    refute(@line_editor.finished?)
    input_keys("\C-j")
    assert_line('ab')
    assert(@line_editor.finished?)
  end

  def test_vi_list_or_eof
    input_keys("\C-d") # quit from inputing
    assert_line(nil)
    assert(@line_editor.finished?)
  end

  def test_vi_list_or_eof_with_non_empty_line
    input_keys('ab')
    assert_byte_pointer_size('ab')
    assert_cursor(2)
    assert_cursor_max(2)
    refute(@line_editor.finished?)
    input_keys("\C-d")
    assert_line('ab')
    assert(@line_editor.finished?)
  end

  def test_completion_journey
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('foo')
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-n")
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-n")
    assert_byte_pointer_size('foo_bar')
    assert_cursor(7)
    assert_cursor_max(7)
    assert_line('foo_bar')
    input_keys("\C-n")
    assert_byte_pointer_size('foo_bar_baz')
    assert_cursor(11)
    assert_cursor_max(11)
    assert_line('foo_bar_baz')
    input_keys("\C-n")
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-n")
    assert_byte_pointer_size('foo_bar')
    assert_cursor(7)
    assert_cursor_max(7)
    assert_line('foo_bar')
    input_keys("_\C-n")
    assert_byte_pointer_size('foo_bar_')
    assert_cursor(8)
    assert_cursor_max(8)
    assert_line('foo_bar_')
    input_keys("\C-n")
    assert_byte_pointer_size('foo_bar_baz')
    assert_cursor(11)
    assert_cursor_max(11)
    assert_line('foo_bar_baz')
    input_keys("\C-n")
    assert_byte_pointer_size('foo_bar_')
    assert_cursor(8)
    assert_cursor_max(8)
    assert_line('foo_bar_')
  end

  def test_completion_journey_reverse
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('foo')
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-p")
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-p")
    assert_byte_pointer_size('foo_bar_baz')
    assert_cursor(11)
    assert_cursor_max(11)
    assert_line('foo_bar_baz')
    input_keys("\C-p")
    assert_byte_pointer_size('foo_bar')
    assert_cursor(7)
    assert_cursor_max(7)
    assert_line('foo_bar')
    input_keys("\C-p")
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-p")
    assert_byte_pointer_size('foo_bar_baz')
    assert_cursor(11)
    assert_cursor_max(11)
    assert_line('foo_bar_baz')
    input_keys("\C-h\C-p")
    assert_byte_pointer_size('foo_bar_ba')
    assert_cursor(10)
    assert_cursor_max(10)
    assert_line('foo_bar_ba')
    input_keys("\C-p")
    assert_byte_pointer_size('foo_bar_baz')
    assert_cursor(11)
    assert_cursor_max(11)
    assert_line('foo_bar_baz')
    input_keys("\C-p")
    assert_byte_pointer_size('foo_bar_ba')
    assert_cursor(10)
    assert_cursor_max(10)
    assert_line('foo_bar_ba')
  end

  def test_completion_journey_in_middle_of_line
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('abcde fo ABCDE')
    assert_line('abcde fo ABCDE')
    input_keys("\C-[" + 'h' * 5 + "i\C-n")
    assert_byte_pointer_size('abcde fo')
    assert_cursor(8)
    assert_cursor_max(14)
    assert_line('abcde fo ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde foo_bar')
    assert_cursor(13)
    assert_cursor_max(19)
    assert_line('abcde foo_bar ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde foo_bar_baz')
    assert_cursor(17)
    assert_cursor_max(23)
    assert_line('abcde foo_bar_baz ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde fo')
    assert_cursor(8)
    assert_cursor_max(14)
    assert_line('abcde fo ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde foo_bar')
    assert_cursor(13)
    assert_cursor_max(19)
    assert_line('abcde foo_bar ABCDE')
    input_keys("_\C-n")
    assert_byte_pointer_size('abcde foo_bar_')
    assert_cursor(14)
    assert_cursor_max(20)
    assert_line('abcde foo_bar_ ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde foo_bar_baz')
    assert_cursor(17)
    assert_cursor_max(23)
    assert_line('abcde foo_bar_baz ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde foo_bar_')
    assert_cursor(14)
    assert_cursor_max(20)
    assert_line('abcde foo_bar_ ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde foo_bar_baz')
    assert_cursor(17)
    assert_cursor_max(23)
    assert_line('abcde foo_bar_baz ABCDE')
  end

  def test_completion
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('foo')
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-i")
    assert_byte_pointer_size('foo_bar')
    assert_cursor(7)
    assert_cursor_max(7)
    assert_line('foo_bar')
  end

  def test_completion_with_disable_completion
    @config.disable_completion = true
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('foo')
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-i")
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
  end

  def test_vi_first_print
    input_keys("abcde\C-[^")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(5)
    input_keys("0\C-ki")
    input_keys(" abcde\C-[^")
    assert_byte_pointer_size(' ')
    assert_cursor(1)
    assert_cursor_max(6)
    input_keys("0\C-ki")
    input_keys("   abcde  ABCDE  \C-[^")
    assert_byte_pointer_size('   ')
    assert_cursor(3)
    assert_cursor_max(17)
  end

  def test_ed_move_to_beg
    input_keys("abcde\C-[0")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(5)
    input_keys("0\C-ki")
    input_keys(" abcde\C-[0")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(6)
    input_keys("0\C-ki")
    input_keys("   abcde  ABCDE  \C-[0")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(17)
  end

  def test_vi_delete_meta
    input_keys("aaa bbb ccc ddd eee\C-[02w")
    assert_byte_pointer_size('aaa bbb ')
    assert_cursor(8)
    assert_cursor_max(19)
    assert_line('aaa bbb ccc ddd eee')
    input_keys('dw')
    assert_byte_pointer_size('aaa bbb ')
    assert_cursor(8)
    assert_cursor_max(15)
    assert_line('aaa bbb ddd eee')
    input_keys('db')
    assert_byte_pointer_size('aaa ')
    assert_cursor(4)
    assert_cursor_max(11)
    assert_line('aaa ddd eee')
  end
end
