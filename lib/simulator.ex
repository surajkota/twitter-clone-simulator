defmodule Simulator do
  @moduledoc """
  Documentation for Simulator.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Simulator.hello
      :world

  """
  def main(args) do
    process(args)
  end

  def process([]) do
    IO.puts "No arguments given"
  end

  def process(args) do
    if length(args) != 2 do
      IO.puts "Run as ./simulator num_of_users <server-ip-address> <simulator-ip-address>"
    else
      _ = System.cmd("epmd", ['-daemon'])
      #Node.start(String.to_atom("client@" <> Enum.at(args, 2)))
      Node.start(String.to_atom("slave@" <> "127.0.0.1"))
      Node.set_cookie(:dsiuvryaaj)
      #Node.connect(String.to_atom("server@" <> Enum.at(args, 1)))
      Node.connect(String.to_atom("server@" <> "127.0.0.1"))
      :global.sync()
      
      hEng = :global.whereis_name(:hashtagEngine)
      mEng = :global.whereis_name(:mentionsEngine)
      rcdEng = :global.whereis_name(:rcdEngine)
      userEng = :global.whereis_name(:userEngine)
      {numUsers, ""} = Integer.parse(Enum.at(args, 0))
      userPidList = loop(rcdEng, userEng, hEng, mEng, numUsers, numUsers, [])
      IO.puts "Starting simulation . . ."
      startloop2(userPidList)
      send userEng, :record
      loop3()
    end
  end 

  def loop(rcdEng, userEng, hEng, mEng, numUsers, number2, clientList) do
      if number2 != 0 do
        IO.puts "number2 is" <> inspect(number2) <> " " <> inspect(numUsers)
          {:ok, pidClient} = Client.start_link(numUsers, number2, []) 
          IO.puts "pidC: " <> inspect(pidClient)
          GenServer.call pidClient, :register
          clientList = [pidClient | clientList]
          loop(rcdEng, userEng, hEng, mEng, numUsers, (number2 - 1), clientList)
        else
          clientList
      end
  end

  def startloop2([user | userPidList]) do
    send user, 0
    startloop2(userPidList)
  end

  def startloop2([]) do
      :ok
  end

  def loop3() do
    loop3()
  end
  
end
