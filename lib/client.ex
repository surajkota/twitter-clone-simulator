defmodule Client do
    use GenServer

    def start_link(rcdEng, userEng, hEng, mEng, nUsers , uId, fList, selUser) do
        #IO.puts "UID is:" <> inspect(uId)
        GenServer.start_link(__MODULE__, [rcdEng, userEng, hEng, mEng, nUsers , uId, fList, selUser])
    end

    def handle_call(:register, _from, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]) do
        if selUser == 0 || selUser == uId do
            IO.puts " Registering: " <> inspect(uId)
        end
        GenServer.call userEng, {:register, uId}
        zipfNum = round((1/uId)*nUsers) # do zipf thing here
        fList = Enum.take_random(Enum.to_list(1..nUsers) -- [uId], zipfNum)
        GenServer.cast userEng, {:subscribe, uId, fList}
        {:reply, :ok, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]}
    end
    
    def handle_cast(:tweet, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]) do
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
        GenServer.cast userEng, {:postTweet, uId, randTweet}
        Process.send_after(self(), 1, uId*10)
        {:noreply, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]}
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
        concatUsers(tList, utag)
    end

    def concatUsers([], utag) do
        utag
    end

    def handle_cast({:recieveTweet, tweets}, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]) do
        #get a tweet from ets, get some hashtags, 
        #IO.puts "tweets are: " <> inspect(tweets) <> "pid: " <> inspect(self())
        if length(tweets) != 0 do
            #IO.puts "lsit isnfisnfi: " <> inspect(tweets) <> "pid: " <> inspect(self())
            forReTweet = tweets
            #tweets = tweets |> Enum.sort_by(&(elem(&1, 1)))
            agg = ""
            agg = Enum.reduce tweets, agg, fn({tid, ts, text}, agg) -> 
                agg = agg <> " \n " <> text 
                agg 
            end
            if selUser == 0 || selUser == uId do
                IO.puts inspect(uId) <> "'s Update: " <> " - " <> agg
            end
            hprob = :rand.uniform()
            if hprob<0.5 do
                #GenServer.cast self(), {:retweet, Enum.random(tweets)}
                {re_tweetid, ts, text} = Enum.random(forReTweet)
                if selUser == 0 || selUser == uId do
                    IO.puts "Retweeting - " <> text
                end
                GenServer.cast userEng, {:reTweet, uId, re_tweetid}
            end
        else
            if selUser == 0 || selUser == uId do
                IO.puts inspect(uId) <> "'s Update: " <> "no new feed"
            end
        end
        {:noreply, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]}
    end

    def handle_cast(:hSearch, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]) do
        #get a hashtag        
        GenServer.cast hEng, {:getTweets, :x, uId}
        #DISPLAY
        #IO.puts "hList: " <> inspect(tweetList)
        """
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
        """
        {:noreply, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]}
    end

    def handle_cast({:recievehSearch, tweets, hashtag}, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]) do
        
        if hashtag == :ok do
            if selUser == 0 || selUser == uId do
                IO.puts "hash search for: " <> inspect("#" <> generateHash(1, "")) <> " - " <> "No tweets"
            end
        else
            agg = ""
            agg = Enum.reduce tweets, agg, fn(text, agg) ->
                agg = agg <> " \n " <> text
                agg
            end
            if selUser == 0 || selUser == uId do
                IO.puts "hash search for: " <> inspect(hashtag) <> " - " <> agg
            end
        end
        {:noreply, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]}
    end 

    def handle_cast({:recievemSearch, tweets, mention}, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]) do
        if mention == :ok do
            if selUser == 0 || selUser == uId do
                IO.puts "mention search for: " <> inspect(uId) <> " - " <> "No tweets"
            end
        else
            agg = ""
            agg = Enum.reduce tweets, agg, fn(text, agg) ->
                agg = agg <> " \n " <> text
                agg
            end
            if selUser == 0 || selUser == uId do
                IO.puts "mention search for: " <> inspect(uId) <> " - " <> agg
            end
        end
        {:noreply, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]}
    end
    
    def handle_cast(:mSearch, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]) do
        #get a tweet from ets, get some hashtags, 
        #{:ok, tweetList1} = GenServer.call :global.whereis_name(:mentionsEngine), {:getTweets, Integer.to_string(:rand.uniform(nUsers))}
        
        GenServer.cast mEng, {:getTweets, uId}
        #DISPLAY
        #IO.puts "tList: " <> inspect(tweetList)
        """
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
        """
        {:noreply, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]}
    end

    def handle_info(msg, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]) do
        cond do
            msg == 0 ->
                if selUser == 0 || selUser == uId do
                    IO.puts "login: " <> inspect(uId)
                end
                GenServer.cast rcdEng, {:login, uId, self()}
                Process.send_after(self(), 1, 0)
            msg == 1 ->
                GenServer.cast self(), :tweet
                << i1 :: unsigned-integer-32, i2 :: unsigned-integer-32, i3 :: unsigned-integer-32>> = :crypto.strong_rand_bytes(12)
                :rand.seed(:exsplus, {i1, i2, i3})
                hprob = :rand.uniform()
                if hprob >0.85 do
                    GenServer.cast self(), :hSearch
                end
                << i1 :: unsigned-integer-32, i2 :: unsigned-integer-32, i3 :: unsigned-integer-32>> = :crypto.strong_rand_bytes(12)
                :rand.seed(:exsplus, {i1, i2, i3})
                :rand.uniform()
                if hprob >0.85 do
                    GenServer.cast self(), :mSearch
                end
                << i1 :: unsigned-integer-32, i2 :: unsigned-integer-32, i3 :: unsigned-integer-32>> = :crypto.strong_rand_bytes(12)
                :rand.seed(:exsplus, {i1, i2, i3})
                hprob = :rand.uniform()
                if hprob >0.7 do
                    if selUser == 0 || selUser == uId do
                        IO.puts "logout: " <> inspect(uId)
                    end
                    GenServer.cast rcdEng, {:logout, uId}
                    Process.send_after(self(), 0, :rand.uniform(10000))
                end
        end
        {:noreply, [rcdEng, userEng, hEng, mEng, nUsers ,uId, fList, selUser]}
    end

end