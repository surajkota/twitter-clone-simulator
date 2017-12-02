defmodule Client do
    use GenServer

    def start_link(nUsers , uId, fList) do
        #IO.puts "UID is:" <> inspect(uId)
        GenServer.start_link(__MODULE__, [nUsers , uId, fList])
    end

    def handle_call(:register, _from, [nUsers ,uId, fList]) do
        IO.puts inspect(:global.whereis_name(:userEngine)) <> " registering: " <> inspect(uId)
        GenServer.call :global.whereis_name(:userEngine), {:register, uId}
        zipfNum = round((1/uId)*nUsers) # do zipf thing here
        fList = Enum.take_random(Enum.to_list(1..nUsers) -- [uId], zipfNum)
        GenServer.cast :global.whereis_name(:userEngine), {:subscribe, uId, fList}
        {:reply, :ok, [nUsers ,uId, fList]}
    end
    
    def handle_cast(:tweet, [nUsers ,uId, fList]) do
        #generate a tweet, n some hashtags,
        randTweet = :crypto.strong_rand_bytes((Enum.random(8..40)) |> round) |> Base.url_encode64
        randHashes = ""
        hprob = :rand.uniform(10)
        if hprob >4 do
            randHashes = generateHash(:rand.uniform(3), "")
            #IO.puts "hahes: " <> inspect(randHashes)
        end
        #tag some users
        utag = ""
        hprob = :rand.uniform(10)
        if hprob>7 do
            tList = Enum.take_random(Enum.to_list(1..nUsers) -- [uId], :rand.uniform(3))
            utag = concatUsers(tList, "")
        end
        randTweet = randTweet <> randHashes <> utag
        #CHANGE TO CAST
        GenServer.cast :global.whereis_name(:userEngine), {:postTweet, uId, randTweet}
        Process.send_after(self(), 1, uId)
        {:noreply, [nUsers ,uId, fList]}
    end

    def generateHash(nHashes, hashes) do
        if nHashes == 0 do
            #IO.puts "***h: " <> inspect(hashes)
            hashes    
        else
            hashes = hashes <> " #" <> (:crypto.strong_rand_bytes(:rand.uniform(3)+1) |> Base.url_encode64)
            generateHash((nHashes-1), hashes)
        end
    end

    def concatUsers([tag | tList], utag) do
        utag = utag <> " @"<> Integer.to_string(tag)
    end

    def concatUsers([], utag) do
        utag
    end

    def handle_cast({:recieveTweet, tweets}, [nUsers ,uId, fList]) do
        #get a tweet from ets, get some hashtags, 
        #IO.puts "tweets are: " <> inspect(tweets) <> "pid: " <> inspect(self())
        if length(tweets) != 0 do
            #IO.puts "lsit isnfisnfi: " <> inspect(tweets) <> "pid: " <> inspect(self())
            forReTweet = tweets
            tweets = tweets |> Enum.sort_by(&(elem(&1, 1)))
            agg = ""
            agg = Enum.reduce tweets, agg, fn({tid, ts, text}, agg) -> 
                agg = agg <> " \n " <> text 
                agg 
            end
            IO.puts inspect(uId) <> "'s Update: " <> " - " <> agg
            hprob = :rand.uniform(10)
            if hprob>7 do
                #GenServer.cast self(), {:retweet, Enum.random(tweets)}
                {re_tweetid, ts, text} = Enum.random(forReTweet)
                #IO.puts "Retweeting: " <> inspect(re_tweetid)
                GenServer.cast :global.whereis_name(:userEngine), {:reTweet, uId, re_tweetid}
            end
        else
            IO.puts inspect(uId) <> "'s Update: " <> "no new feed"
        end
        {:noreply, [nUsers ,uId, fList]}
    end

    def handle_cast(:hSearch, [nUsers ,uId, fList]) do
        #get a hashtag 
        {hash, tweetList} = GenServer.call :global.whereis_name(:hashtagEngine), {:getTweets, :x}
        #DISPLAY
        #IO.puts "hList: " <> inspect(tweetList)
        if hash == :ok do
            IO.puts "hash search for: " <> inspect("#" <> generateHash(1, "")) <> " - " <> "No tweets"
        else
            agg = ""
            agg = Enum.reduce tweetList, agg, fn(text, agg) -> 
                agg = agg <> " \n " <> text 
                agg 
            end
            IO.puts "hash search for: " <> inspect(hash) <> " - " <> agg
        end
        {:noreply, [nUsers ,uId, fList]}
    end
    
    def handle_cast(:mSearch, [nUsers ,uId, fList]) do
        #get a tweet from ets, get some hashtags, 
        #{:ok, tweetList1} = GenServer.call :global.whereis_name(:mentionsEngine), {:getTweets, Integer.to_string(:rand.uniform(nUsers))}
        {mention, tweetList} = GenServer.call :global.whereis_name(:mentionsEngine), {:getTweets, uId}
        #DISPLAY
        #IO.puts "tList: " <> inspect(tweetList)
        if mention == :ok do
            IO.puts "mention search for: " <> inspect(uId) <> " - " <> "No tweets"
        else
            agg = ""
            agg = Enum.reduce tweetList, agg, fn(text, agg) -> 
                agg = agg <> " \n " <> text 
                agg 
            end
            IO.puts "mention search for: " <> inspect(uId) <> " - " <> agg
        end
        {:noreply, [nUsers ,uId, fList]}
    end

    def handle_info(msg, [nUsers ,uId, fList]) do
        cond do
            msg == 0 ->
                GenServer.call :global.whereis_name(:rcdEngine), {:login, uId, self()}
                Process.send_after(self(), 1, 0)
            msg == 1 ->
                GenServer.cast self(), :tweet
                hprob = :rand.uniform(10)
                if hprob >7 do
                    GenServer.cast self(), :hSearch
                end
                hprob = :rand.uniform(10)
                if hprob >7 do
                    GenServer.cast self(), :mSearch
                end
                hprob = :rand.uniform(10)
                if hprob >9 do
                    GenServer.call :global.whereis_name(:rcdEngine), {:logout, uId}
                    Process.send_after(self(), 0, :rand.uniform(1000))
                end
        end
        {:noreply, [nUsers ,uId, fList]}
    end

end