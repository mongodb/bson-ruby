# rubocop:todo all
module Utils
  extend self

  # JRuby chokes when strings like "\xfe\x00\xff", which are not valid UTF-8,
  # appear in the source. Use this method to build such strings.
  # char_array is an array of byte values to use for the string.
  def make_byte_string(char_array, encoding = 'BINARY')
    char_array.map do |char|
      char.chr.force_encoding('BINARY')
    end.join.force_encoding(encoding)
  end

  # Forks the current process and executes the given block in the child.
  # The value returned by the block is then returned in the parent process
  # by this method.
  #
  # @return [ Object ] the value returned by the block
  def perform_in_child(&block)
    reader, writer = IO.pipe

    if fork
      parent_worker(reader, writer)
    else
      child_worker(reader, writer, &block)
    end
  end

  private

  # A utility method for #perform_in_child, to handle tasks for the parent
  # side of the fork.
  #
  # @param [ IO ] reader The reader IO for the pipe
  # @param [ IO ] writer The writer IO for the pipe
  #
  # @return [ Object ] the value returned by the child process
  def parent_worker(reader, writer)
    writer.close
    blob = reader.read
    reader.close
    Process.wait
    Marshal.load(blob)
  end

  # A utility method for #perform_in_child, to handle tasks for the child
  # side of the fork.
  #
  # @param [ IO ] reader The reader IO for the pipe
  # @param [ IO ] writer The writer IO for the pipe
  def child_worker(reader, writer, &block)
    reader.close
    result = block.call
    writer.write Marshal.dump(result)
    writer.close
    exit! 0
  end
end
