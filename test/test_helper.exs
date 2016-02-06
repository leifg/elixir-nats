# Copyright 2016 Apcera Inc. All rights reserved.
#ExUnit.configure exclude: [disabled: true]
ExUnit.start

defmodule TestHelper do

  @jobs_or_die "jobs; jobs -p|read||exit\n"
  def gnatsd_conf_dir, do: "test/conf"
  def gnatsd_conf_file(file), do: gnatsd_conf_dir <> "/" <> file
  
  def run_gnatsd(opts  \\ "") do
    #setup_all
    Porcelain.reinit(Porcelain.Driver.Basic)
    IO.puts "starting gnatsd..."
    console = IO.binstream(:standard_io, :line)
    res = Porcelain.spawn_shell("bash", out: console, err: console)
    Porcelain.Process.send_input res, "gnatsd #{opts} < /dev/null 2>&1 &\n"
    :timer.sleep(1_000)
    _running = gnatsd?(res)
#    IO.puts "hopefully we are done(#{running})... #{inspect res2}"
    res
  end
  def stop_gnatsd(gnatsd) do
    # this may not stop gnatsd... ;-)
    Porcelain.Process.send_input gnatsd, @jobs_or_die
    alive? = Porcelain.Process.alive?(gnatsd)
    IO.puts "stopping gnatsd (#{alive?})"
    Porcelain.Process.send_input gnatsd, "jobs; kill %1; sleep 1; jobs\n"
    res = Porcelain.Process.stop(gnatsd)
    res
  end
  def gnatsd?(gnatsd) do
#    IO.puts "checking... #{inspect gnatsd}: #{Porcelain.Process.alive?(gnatsd)}"
    yes = Porcelain.Process.alive?(gnatsd) 
    yes && Porcelain.Process.send_input gnatsd, @jobs_or_die
    yes
  end
  
  defmacro assert_parse_error(binary) do
    quote do
      { v, _rest, _ } = Nats.Parser.parse(unquote(binary))
      assert v == :error
    end
  end

  defmacro assert_verb_parse_encode(binary, expected_verb) do
    quote bind_quoted: [
        binary: binary,
        expected_verb: expected_verb
      ] do
      assert {:ok, verb, "", _} = Nats.Parser.parse(binary)
      assert verb == expected_verb
      out = encode(verb)
      assert out == binary
    end
  end

  defmacro assert_parses([binary: b, expected: expected]) do
    quote do
      assert_parses([binary: unquote(b), expected: unquote(expected), encoded: unquote(b) ])
    end
  end

  defmacro assert_parses([binary: binary, expected: expected, encoded: encoded]) do
    quote do
      binary   = unquote(binary)
      expected = unquote(expected)
      encoded  = unquote(encoded)
      {:ok, v, "", _} = Nats.Parser.parse(binary)
      assert v == expected
      assert encode(v) == encoded
    end
  end
end

