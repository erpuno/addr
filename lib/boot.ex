defmodule ADDR.Boot do
  require KVS
  require Record

  Record.defrecord(:writer, Record.extract(:writer, from_lib: "kvs/include/cursors.hrl"))
  Record.defrecord(:reader, Record.extract(:reader, from_lib: "kvs/include/cursors.hrl"))
  Record.defrecord(:atu,    Record.extract(:atu,    from: "include/atsu.hrl"))
  Record.defrecord(:'Addr', Record.extract(:'Addr',  from: "include/atsu.hrl"))

  @feed     Application.get_env(:addr, :feed, "/АТОТТГ")
  @registry Application.get_env(:addr, :register, :code.priv_dir(:addr) ++ '/katottg/katottg_29.11.2022.zip')
  @address  Application.get_env(:addr, :addresses, [
    '/katottg/address_BI_20.12.2021.zip',
    '/katottg/address_AT_20.12.2021.zip',
    '/katottg/address_AM_20.12.2021.zip',
    '/katottg/address_AC_20.12.2021.zip',
    '/katottg/address_AX_20.12.2021.zip',
    '/katottg/address_AO_20.12.2021.zip',
    '/katottg/address_AI_20.12.2021.zip',
    '/katottg/address_BT_20.12.2021.zip',
    '/katottg/address_BA_20.12.2021.zip',
    '/katottg/address_CE_20.12.2021.zip',
    '/katottg/address_AP_20.12.2021.zip',
    '/katottg/address_BM_20.12.2021.zip',
    '/katottg/address_AB_20.12.2021.zip',
    '/katottg/address_CB_20.12.2021.zip',
    '/katottg/address_BB_20.12.2021.zip',
    '/katottg/address_CA_20.12.2021.zip',
    '/katottg/address_AH_20.12.2021.zip',
    '/katottg/address_BO_20.12.2021.zip',
    '/katottg/address_BH_20.12.2021.zip',
    '/katottg/address_AE_20.12.2021.zip',
    '/katottg/address_BC_20.12.2021.zip',
    '/katottg/address_BK_20.12.2021.zip',
    '/katottg/address_BE_20.12.2021.zip',
    '/katottg/address_BX_20.12.2021.zip']
    |> Enum.map(fn region -> :code.priv_dir(:addr) ++ region end)
  )

  def boot() do
    case :kvs.get(:writer, @feed) do
      {:ok, writer(count: count)} ->
        IO.puts("Administrative unit loaded: #{inspect(count)}")
      _ ->
        normalize = fn s ->
          s |> String.split("\"", trim: true) |> Enum.join("\u02BC")
            |> :string.casefold
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

        addr_file = fn file ->
          feeds = Process.get(:feed)
          spawn(fn ->
            Process.put(:feed, feeds)

            IO.puts "Importing #{inspect(file)} ..."
            {:ok, [{_,bin}]} = file |> :zip.unzip([:memory])

            :binary.split(bin, ["\n", "\r\n", "\r"], [:global])
              |> Enum.map(&String.split(&1,";"))
              |> Enum.flat_map(fn
                ["DC_LOCALITY",_,_,_,"KATOTTG",_,_,_,_,_,_,"Path"] -> []
                [id,pid,name,_,katottg,_,_,_,_,obj,abb,path] -> [unquote(:'Addr')(id: id,
                                                                  parent_id: pid,
                                                                  katottg: katottg,
                                                                  name: normalize.(name),
                                                                  abbreviation: abb,
                                                                  loc_name: obj,
                                                                  path: normalize.(path))]
                                                    _ -> []
                end)
              |> Enum.each(&address(&1))
            IO.puts("#{inspect(file)} done.")
            Process.delete :feed
            end)
        end

        @address |> Enum.each(&addr_file.(&1))

        Process.delete :feed
    end
  end

  def level(atu(id: code, name: name) = atu) do
    #//UA|ОО|РР|ГГГ|ППП|ММ|УУУУУ:
    #IO.puts "#{inspect(is_binary(code))}"
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

            x0 = Map.get(feed, o)
            x1 = Map.get(feed, [o,p] |> List.flatten |> Enum.join("/"))
            x2 = Map.get(feed, [o,p,g] |> List.flatten |> Enum.join("/"))
            x3 = Map.get(feed, [o,p,g,n] |> List.flatten |> Enum.join("/"))
            x4 = Map.get(feed, [o,p,g,n,a] |> List.flatten |> Enum.join("/"))

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
