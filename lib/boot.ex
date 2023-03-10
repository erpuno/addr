defmodule ADDR.Boot do
  require KVS
  require Record

  Record.defrecord(:writer, Record.extract(:writer, from_lib: "kvs/include/cursors.hrl"))
  Record.defrecord(:reader, Record.extract(:reader, from_lib: "kvs/include/cursors.hrl"))
  Record.defrecord(:atu,    Record.extract(:atu,    from: "include/atsu.hrl"))
  Record.defrecord(:'Addr', Record.extract(:'Addr', from: "include/atsu.hrl"))

  @feed     Application.get_env(:addr, :feed, "/АТОТТГ")
  @registry Application.get_env(:addr, :register, :code.priv_dir(:addr) ++ '/katottg/katottg_29.11.2022.zip')
  @registry_upd Application.get_env(:addr, :units, :code.priv_dir(:addr) ++ '/address/dcu_10.03.2023.zip')
  @address Application.get_env(:addr, :address, [
    '/address/dca10_10.03.2023.zip',
    '/address/dca16_10.03.2023.zip',
    '/address/dca21_10.03.2023.zip',
    '/address/dca27_10.03.2023.zip',
    '/address/dca5_10.03.2023.zip',
    '/address/dca11_10.03.2023.zip',
    '/address/dca17_10.03.2023.zip',
    '/address/dca22_10.03.2023.zip',
    '/address/dca28_10.03.2023.zip',
    '/address/dca6_10.03.2023.zip',
    '/address/dca12_10.03.2023.zip',
    '/address/dca18_10.03.2023.zip',
    '/address/dca23_10.03.2023.zip',
    '/address/dca29_10.03.2023.zip',
    '/address/dca7_10.03.2023.zip',
    '/address/dca13_10.03.2023.zip',
    '/address/dca19_10.03.2023.zip',
    '/address/dca24_10.03.2023.zip',
    '/address/dca2_10.03.2023.zip',
    '/address/dca8_10.03.2023.zip',
    '/address/dca14_10.03.2023.zip',
    '/address/dca1_10.03.2023.zip',
    '/address/dca25_10.03.2023.zip',
    '/address/dca3_10.03.2023.zip',
    '/address/dca9_10.03.2023.zip',
    '/address/dca15_10.03.2023.zip',
    '/address/dca20_10.03.2023.zip',
    '/address/dca26_10.03.2023.zip',
    '/address/dca4_10.03.2023.zip'
    ] |> Enum.map(fn index -> :code.priv_dir(:addr) ++ index end))

  def boot() do
    case :kvs.get(:writer, @feed) do
      {:ok, writer(count: count)} ->
        IO.puts("Address: #{inspect(count)}")
      _ ->
        normalize = fn s ->
          s |> String.split("\"", trim: true) |> Enum.join("\u02BC")
            |> :string.casefold
            |> :string.trim
        end

        atus = fn (unquote(:'Addr')(kind: 70)) -> :skip
                  (unquote(:'Addr')(id: id,
                                    parent_id: pid,
                                    name: name,
                                    kind: _kind) = _add) ->
          name = case name do "україна" -> String.trim_leading(@feed, "/");_ -> name end

          feeds = Process.get(:feeds, %{})
          feed = Map.get(feeds, pid, "")
          feed = String.trim_trailing(feed, "/")
          feed = "#{feed}/#{name}"
          Process.put(:feeds, Map.put(feeds, id, feed))
        end

        streets = fn ((unquote(:'Addr')(id: _id,
                                       parent_id: pid,
                                       name: name,
                                       kind: 70,
                                       katottg: _katottg) = add)) ->
            feeds = Process.get(:feeds, %{})
            feed = Map.get(feeds, pid, "")
            feed = String.trim_trailing(feed, "/")
            path = feed
              |> String.split([@feed, "/"], trim: true)
              |> Kernel.++([name])
              |> Enum.join("\\")

            unit = (unquote(:'Addr')(add, path: path))
            :kvs.append(unit, feed)
          (_) ->:skip
        end

        {:ok, [{_,bin}]} = @registry_upd |> :zip.unzip([:memory])
        IO.puts "Import administrative unit register: "
        :binary.split(bin, ["\n", "\r\n", "\r"], [:global])
          |> Stream.map(&String.split(&1,","))
          |> Stream.flat_map(fn
            [id,pid,name,_,katottg,_,n,_,_,abbr] ->
              try do
                [unquote(:'Addr')(id: id,
                  parent_id: pid,
                  katottg: katottg,
                  name: normalize.(name),
                  abbreviation: abbr,
                  kind: :erlang.binary_to_integer(n)
                )]
                rescue _e ->
                  IO.puts "broken record #{id} - #{pid}"
                  []
                end
            _ -> []
            end)
          |> Enum.each(&atus.(&1))

        part = fn file ->
          IO.puts "Importing #{file}..."
          feeds = Process.get(:feeds)
          spawn(fn ->
            Process.put(:feeds, feeds)
            {:ok, [{_,bin}]} = file |> :zip.unzip([:memory])

            :binary.split(bin, ["\n", "\r\n", "\r"], [:global])
              |> Stream.map(&String.split(&1,","))
              |> Stream.flat_map(fn
                [id,pid,name,_,_,katottg,n,_,_,abbr] ->
                  try do
                    [unquote(:'Addr')(id: id,
                      parent_id: pid,
                      katottg: katottg,
                      name: normalize.(name),
                      abbreviation: abbr,
                      kind: :erlang.binary_to_integer(n)
                    )]
                    rescue _e ->
                      IO.puts "broken record #{id} #{pid} #{file}"
                      []
                    end
               _ -> []
                end)
              |> Enum.each(&streets.(&1))
            IO.puts "#{file} done."
          end)
        end

        @address |> Enum.each(&part.(&1))
    end
  end

  def registry() do
    case :kvs.get(:writer, @feed) do
      {:ok, writer(count: count)} ->
        IO.puts("Administrative unit loaded: #{inspect(count)}")
      _ ->
        normalize = fn s ->
          s |> String.split("\"", trim: true) |> Enum.join("\u02BC")
            |> :string.casefold
            |> :string.trim
        end

        IO.puts("Import administrative unit register into #{inspect(@feed)} ..")
        {:ok, [{_, bin}]} = @registry |> :zip.unzip([:memory])

        :binary.split(bin, ["\n", "\r\n", "\r"], [:global])
          |> Enum.map(&String.split(&1,";"))
          |> Enum.flat_map(fn
            [id,"","","","",cat,name] -> [atu(id: id, name: normalize.(name), category: cat)]
            [_, id,"","","",cat,name] -> [atu(id: id, name: normalize.(name), category: cat)]
            [_, _, id,"","",cat,name] -> [atu(id: id, name: normalize.(name), category: cat)]
            [_, _, _, id,"",cat,name] -> [atu(id: id, name: normalize.(name), category: cat)]
            [_, _, _, _, id,cat,name] -> [atu(id: id, name: normalize.(name), category: cat)]
                                    _ -> []
            end)
          |> Enum.each(&level(&1))
    end
  end

  def level(atu(id: code, name: name) = atu) do
    #//UA|ОО|РР|ГГГ|ППП|ММ|УУУУУ:
    case code do
      <<"UA", o::binary-size(2), "00", "000", "000", "00", uid::binary-size(5)>> ->
        feed = Process.get :feed, %{}
        feed1 = "#{@feed}/#{name}"
        Process.put(:feed, Map.put(feed, o, name))

        unit = atu(atu, id: code, code: uid)

        :kvs.append(unit, feed1)

      <<"UA", o::binary-size(2), p::binary-size(2), "000", "000", "00", uid::binary-size(5)>> ->
        feed = Process.get :feed, %{}
        fee0 = Map.get(feed, o)
        fee1 = "#{@feed}/#{fee0}"

        Process.put(:feed, Map.put(feed, "#{o}/#{p}", name))

        unit = atu(atu, id: code, code: uid)
        :kvs.append(unit, fee1)

      <<"UA", o::binary-size(2), p::binary-size(2), g::binary-size(3), "000", "00", uid::binary-size(5)>> ->
        feed = Process.get :feed, %{}
        fee0 = Map.get(feed, o)
        fee1 = Map.get(feed, "#{o}/#{p}")
        fee2 = "#{@feed}/#{fee0}/#{fee1}"

        Process.put(:feed, Map.put(feed, "#{o}/#{p}/#{g}", name))

        unit = atu(atu, id: code, code: uid)

        :kvs.append(unit, fee2)

      <<"UA", o::binary-size(2), p::binary-size(2), g::binary-size(3), n::binary-size(3), "00", uid::binary-size(5)>> ->
        feed = Process.get :feed, %{}
        fee0 = Map.get(feed, o)
        fee1 = Map.get(feed, "#{o}/#{p}")
        fee2 = Map.get(feed, "#{o}/#{p}/#{g}")
        fee3 = "#{@feed}/#{fee0}/#{fee1}/#{fee2}"

        Process.put(:feed, Map.put(feed, "#{o}/#{p}/#{g}/#{n}", name))

        unit = atu(atu, id: code, code: uid)
        :kvs.append(unit, fee3)
      <<"UA", o::binary-size(2), p::binary-size(2),g::binary-size(3), n::binary-size(3), a::binary-size(2), uid::binary-size(5)>> -> 
        feed = Process.get :feed, %{}
        fee0 = Map.get(feed, o)
        fee1 = Map.get(feed, "#{o}/#{p}")
        fee2 = Map.get(feed, "#{o}/#{p}/#{g}")
        fee3 = "#{@feed}/#{fee0}/#{fee1}/#{fee2}"
        fee4 = "#{@feed}/#{fee0}/#{fee1}/#{fee2}/#{fee3}"

        Process.put(:feed, Map.put(feed, "#{o}/#{p}/#{g}/#{n}/#{a}", name))

        unit = atu(atu, id: code, code: uid)
        :kvs.append(unit, fee4)

      <<"UA", o::binary-size(2), "00", "000", "000", _p::binary-size(2), uid::binary-size(5)>> ->

        feed = Process.get :feed, %{}
        fee0 = Map.get(feed, o)
        fee1 = "#{@feed}/#{fee0}"

        unit = atu(atu, id: code, code: uid)
        :kvs.append(unit, fee1)
      x ->
        IO.puts "not match #{inspect(x)}"
    end
  end

  def address(unquote(:'Addr')(katottg: code) = addr) do
    #//DC_LOCALITY_ID;PARENT_ID;NAME;KOATUU;KATOTTG;POST_CODE;KIND;LOCALITY_ST_ID;UKR_POST_ID;LOC_NAME;ABBREVIATION;Path
    #//UA|ОО|РР|ГГГ|ППП|ММ|УУУУУ:
    case code do
      c when c in [<<>>,"0"] ->
        case Process.get(:code) do 
          nil -> :ok
          <<"UA", o::binary-size(2),
                  p::binary-size(2),
                  g::binary-size(3),
                  n::binary-size(3),
                  a::binary-size(2),
                  _::binary-size(5)>> ->
            feed = Process.get :feed, %{}

            trm = fn("") -> [];(fd) -> fd end
            x0 = trm.(Map.get(feed, o, []))
            x1 = trm.(Map.get(feed, [o,p] |> List.flatten |> Enum.join("/"), []))
            x2 = trm.(Map.get(feed, [o,p,g] |> List.flatten |> Enum.join("/"), []))
            x3 = trm.(Map.get(feed, [o,p,g,n] |> List.flatten |> Enum.join("/"), []))
            x4 = trm.(Map.get(feed, [o,p,g,n,a] |> List.flatten |> Enum.join("/"), []))

            feed4 = ["/АТОТТГ",x0,x1,x2,x3,x4] |> List.flatten |> Enum.join("/")

            :kvs.append(addr, feed4)
          x ->
            IO.puts "skip #{inspect(x)}"
        end
      _ ->
        Process.put(:code, code)
    end
  end
end
