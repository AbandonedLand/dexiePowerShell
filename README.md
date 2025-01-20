# Dexie API PowerShell Module

This PowerShell module provides functions to interact with the [Dexie API](https://dexie.space/api), allowing you to build URLs, retrieve Chia Asset Tokens (CATs), send offers, search for offers, and more.

To get the most out of the functions, assign them to a variable at runtime like this:

```powershell
$offer = Get-DexieOffer -dexie_id 9dJtYToVpcG7UvapnWQH51A4iBWTMRfBXVwrXgfnvEej -result_only

$offer.id
9dJtYToVpcG7UvapnWQH51A4iBWTMRfBXVwrXgfnvEej

$offer.offered
id  code name amount
--  ---- ---- ------
xch XCH  Chia     20

$offer.requested
id                                                               code    name                 amount
--                                                               ----    ----                 ------
fa4a180ac326e67ea289b869e3448256f6af05721f7cf934cb9901baa6b7a99d wUSDC.b Base warp.green USDC 318.62

$offer.price
15.931


```

## Functions

### `Get-DexieAssets`

 Retrieve a list of Chia Asset Tokens (CATs) from the dexie asset endpoint.

#### Description
Query dexie.space for a list of recognized assets on the Chia Blockchain.

#### Parameters
- **page**: Results are limited to a certain number per page.  Increase the page to get more results.
- **page_size**: page_size determines how many results are displayed per query.  Max is 100.
- **results_only**: Return the results without query metadata.

#### Examples
```powershell
Get-DexieAssets

Output:
            success   : True
            count     : 2203
            page      : 1
            page_size : 50
            assets    : {@{id=a628c1c2c6fcb74d53746157e438e10...}


Get-DexieAssets -results_only

Output: 
            id                : a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913
            code              : SBX
            name              : Spacebucks
            category          : meme
            website           : https://spacebuckscoin.com
            description       : The galactic monetary standard.
            verification      : 
            denom             : 
            liquidity         : {167.971488442385, 13338930.197}
            current_avg_price : 2.89460957623726E-05
            volume            : {20.136492055295, 714560}

            id                : ccda69ff6c44d687994efdbee30689be51d2347f739287ab4bb7b52344f8bf1d
            code              : BEPE
            name              : BEPE
            category          : 
            website           : 
            description       : BEPE, the memecoin Chia BitTorrent wizard would unleash if he ever released his inner degen
            verification      : 
            denom             : 
            liquidity         : {268.46, 99790387}
            current_avg_price : 2.58520788774538E-06
            volume            : {0.024519545905, 9434.979}

            ... 

```

### `Send-DexieOffer`
 Send an offer to the dexie.space API Endpoint.
#### Description
Sends your offer to dexie.space for listing on their exchange.  The offer file is created using the 
        chia wallet.  Offers are a secure way to trade one asset for another on Chia.

#### Parameters
- **offer**: The text string that represents your offer.  The text will start with 'offer'.
- **drop_only**: If this is set, dexie will only return the offer_id when successful.
- **claim_rewards**: If the offer is part of the liquidity rewards program (https://dexie.space/incentives), dexie will
        automatically send the rewards for providing liquidity to your wallet.  This is especially useful if 
        you use automatically expiring offers.


#### Examples
```powershell
Send-DexieOffer -offer "offer1qqz83wc..."

Output:

    success : True
    id      : B18UHqaJXBDu8PVBWsY73opqmCszRnT8hEPmL6rYDcYa
    known   : True
    offer   : @{id=B18UHqaJXBDu8PVBWsY73opqmCszRnT8hEPmL6rYDcYa; 
                status=4; date_found=8/6/2022 7:30:21 AM; 
                date_completed=8/7/2022 12:47:28 AM; 
                date_pending=8/7/2022 12:46:59 AM; 
                date_expiry=8/14/2022 12:46:59 AM; 
                block_expiry=; 
                spent_block_index=2364190; 
                price=79000; offered=System.Object[]; 
                requested=System.Object[]; fees=0}
```


### `Get-DexieOffers`
 Search for offers posted to dexie.space.
#### Description
Query dexie.space for offers that exactly what you're looking for.  This powerful
        tool will help you discover offers to complete.  This can also be used for price
        discovery of things listed on Chia.

#### Parameters
- **status**: This is the status of the offer.  You can find offers that are:
        'Active','Pending','Cancelling','Cancelled','Completed','Unknown','Expired'
        Multiple choices are allowed.
- **offered**: Only include offers which offer this asset. Request by:

        CODE                (XCH,DBX,SBX)
        ASSET ID            (db1a..., e816...)
        NFT Collection ID   (col1...)
        NFT ID              (nft1...)
- **requested**: Only include offers which request this asset. Request by:

        CODE                (XCH,DBX,SBX)
        ASSET ID            (db1a..., e816...)
        NFT Collection ID   (col1...)
        NFT ID              (nft1...)

- **offer_or_requested**: Only include offers which request this asset. Request by:

        CODE                (XCH,DBX,SBX)
        ASSET ID            (db1a..., e816...)
        NFT Collection ID   (col1...)
        NFT ID              (nft1...)

- **offered_type**: Limit results to only CAT2 or NFT.
- **requested_type**: Limit results to only CAT2 or NFT.
- **offered_or_requested_type**: Limit results to only CAT2 or NFT.
- **sort**: Sort the results by price,price_desc,date_completed,date_found.
- **compact**: If included, the result will contain just data related to price.  This
        does not include the offer string to take the offer.
- **include_multiple_requested**:         Include offers that have multiple assets in the requested parameter.
- **page**: Request a specific page of results.
- **page_size**: Request a specific page of results.
- **results_only**: Return only the offers, without the metadata on query.   
#### Examples
```powershell
Get-DexieOffers 

Output:

    success   : True
    count     : 535623
    page      : 1
    page_size : 20
    offers    : {@{id=948...}
```

```powershell
Get-DexieOffers -results_only

Output:

    id                : 9dJtYToVpcG7UvapnWQH51A4iBWTMRfBXVwrXgfnvEej
    status            : 0
    offer             : offer1qqr83wcuu2rykcmqvpsxygqqd2h6fv0lt2sn8...
    involved_coins    : {0x93355a71f83a710fba766ef68a574c82a...}
    date_found        : 8/9/2024 6:44:32 PM
    date_completed    : 
    date_pending      : 
    date_expiry       : 
    block_expiry      : 5763294
    spent_block_index : 
    price             : 15.931
    offered           : {@{id=xch; code=XCH; name=Chia; amount=20}}
    requested         : {@{id=fa4a180ac326e67ea289b869e344...}
    fees              : 0
    mempool           : 
    related_offers    : {}
    mod_version       : 2
    trade_id          : 0x08add4531e9c810976736a671d5edffd372833a1c5d792f...
    known_taker       : 
```

```powershell
Get-DexieOffers -status Completed -offered col1aufdw4wm8mph9rdtqljg3nm22k8c6wapuqgfr0mp0anpfhkhn7as6nkpp2 -requested XCH -page_size 2 -page 1 -compact

Output:

    success   : True
    count     : 209
    page      : 1
    page_size : 2
    offers    : {@{id=AviVywhpm9MPpFFRvPSPiYBmCiqgKo5k6CmoozH2cqSQ; stat...}

```


### `Get-DexieOffer`
 Get the offer details for a specific offer on dexie.space.
#### Description
Look up an offer on dexie.space

#### Parameters
- **dexie_id**: The dexie_id is a Base58 encoded hash of the offer file or the hash of the spend bundle (a.k.a. trade_id)
- **results_only**: Return only the offers, without the metadata on query. 

#### Examples
```powershell
Get-DexieOffer -dexie_id HR7aHbCXsJto7iS9uBkiiGJx6iGySxoNqUGQvrZfnj6B

Output:

    success : True
    offer   : @{id=HR7aHbCXsJto7iS9uBkiiGJx6iGySxoNqUGQvrZfnj6B; status=0; ...}
```

```powershell
Get-DexieOffer -dexie_id HR7aHbCXsJto7iS9uBkiiGJx6iGySxoNqUGQvrZfnj6B -result_only

Output:

    id                : HR7aHbCXsJto7iS9uBkiiGJx6iGySxoNqUGQvrZfnj6B
    status            : 4
    offer             : offer1qq.....
    involved_coins    : {0xac057183bb929bf7f1a585f38ecafab6f22c0339c02ba08b50ceae1ae5b95b11, 0x8535fc352894b853c7832ee5ef30c7e638156bd20b8f3ddbabc68cc12989d389, 0xe5dcfc32fcf827764ab9022539a45d8c3e5681d0572a0279c042c9b5f0f10f73,
                        0xda6a1b341b2c6d0567196469e8cb39d6751710b555f196b8e1cf4955890ade63…}
    date_found        : 8/6/2022 8:28:49 AM
    date_completed    : 8/7/2022 1:55:19 PM
    date_pending      : 8/7/2022 1:55:11 PM
    spent_block_index : 2366671
    price             : 99009.900990099
    offered           : {@{id=xch; code=XCH; name=Chia; amount=1.01}}
    requested         : {@{id=a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913; code=SBX; name=Spacebucks; amount=100000}}
    fees              : 0
    mempool           : 
    related_offers    : {}
    mod_version       : 1
    trade_id          : 0x9228a97feb1047f708a7f563565b1611b7b742e30f2b4a968035019e90ff2959
    known_taker       : 
    input_coins       : @{xch=System.Object[]; 0xa628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913=System.Object[]}
    output_coins      : @{xch=System.Object[]; 0xa628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913=System.Object[]}
```

### `Get-DexiePairs`
 Get a list of all XCH-CAT pairs.
#### Description
Find XCH-Cat pairs on dexie.space that have had at least one XCH trade.

#### Parameters

- **results_only**: Return only the offers, without the metadata on query. 

#### Examples
```powershell
Get-DexiePairs

Output:

    pairs   : {@{ticker_id=()_XCH; base=();...}
    success : True
```

```powershell
Get-DexiePairs -results_only

Output:

        ticker_id               base                target pool_id
        ---------               ----                ------ -------
        ()_XCH                  ()                  XCH    6ad656d5d7c8216da8ce520113073fb0da0fbc6cebc47eb21cf4704d9f80cbc9
        🥔_XCH                  🥔                 XCH    1e458e659657f2f945e90f8e0cc115e1b4f8d190df8151bbe715c9851a5ff219
        $CHIA_XCH               $CHIA               XCH    2f88f387ad7fc024764ab8aa3038da7abf86e302bbed05e918d837dcdd21940b
        0000_XCH                0000                XCH    2d7521213568de1b6b4912ac5867e2dc5767ae69444aec9e7d46e0162343c712
        42_XCH                  42                  XCH    d86bdd3dc1546a1baa023f4573c38b8f6f3507a56f5af06fb3b34e1ab4fb6da2
        ..........
            
            
```



### `Get-DexieTickers`
 Gather basic trading information on specific ticker_ids.
#### Description
Gather information on ticker_ids.  Ticker_ids can be found using Get-DexiePairs.

#### Parameters

- **ticker_id**: The ticker_id is in the BASE_XCH format where BASE is the CAT2 code from Get-DexieAssets.  
You can also find ticker_ids from Get-DexiePairs.
- **results_only**: Return only the offers, without the metadata on query. 

#### Examples
```powershell
Get-DexieTickers

Output:

        success : True
        tickers : {@{ticker_id=()_XCH; base_currency=(); target_currency=XCH; base_id=4bf5122f...}
```

```powershell
Get-DexieTickers -ticker_id DBX_XCH -results_only

Output:

        ticker_id         : DBX_XCH
        base_currency     : DBX
        target_currency   : XCH
        base_id           : db1a9020d48d9d4ad22631b66ab4b9ebd3637ef7758ad38881348c5d24c38f20
        target_id         : xch
        base_name         : dexie bucks
        target_name       : Chia
        last_price        : 0.001075728439131916
        current_avg_price : 0.0010842441686799912
        base_volume       : 402.173
        target_volume     : 0.432628933551
        base_volume_7d    : 14298.88
        target_volume_7d  : 15.26392515273
        base_volume_30d   : 219654.788
        target_volume_30d : 274.920135274194
        pool_id           : 7cd49885b4989bceafbd07cc68b05d9b75e3a43cb2ac85049e4b07ea42e9b9f4
        bid               : 0.0010493913857677903
        ask               : 0.0011208
        high              : 0.001075728439131916
        low               : 0.001075728439131916
            
            
```




### `Get-DexieOrderBook`
 Get the current orderbook for trading pair on dexie.space.
#### Description
Pulls the Bid/Ask orderbook from dexie.space. 

#### Parameters

- **ticker_id**: The ticker_id is in the BASE_XCH format where BASE is the CAT2 code from Get-DexieAssets.  
You can also find ticker_ids from Get-DexiePairs.

- **depth**: How many XCH deep to gather offers for.
- **results_only**: Return only the offers, without the metadata on query. 

#### Examples
```powershell
Get-DexieOrderBook -ticker_id DBX_XCH

Output:

    success   : True
    orderbook : @{ticker_id=DBX_XCH; pool_id=7cd4...}
```

```powershell
Get-DexieOrderBook -ticker_id DBX_XCH -results_only

Output:

    ticker_id : DBX_XCH
    pool_id   : 7cd49885b4989bceafbd07cc68b05d9b75e3a43cb2ac85049e4b07ea42e9b9f4
    timestamp : 1723233351153
    bids      : {0.00106097717832543502 4688.131, 0.00104939138576779026 427.2, 0.00104761904761904762 10500, 0.00104333502280790674 394.6…}
    asks      : {0.0011208 5000, 0.00112509736183219611 406.987, 0.00113777777777777778 3600, 0.00115833333333333333 3600…}
```

### `Get-DexieHistoricalTrades`
 Get Historical trades on dexie.space for a given ticker_id.
#### Description
Query the completed trades on dexie.space for givin ranges.


#### Parameters

- **ticker_id**: The ticker_id is in the BASE_XCH format where BASE is the CAT2 code from Get-DexieAssets.  
You can also find ticker_ids from Get-DexiePairs.

- **limit**:  Limit number of results.
- **type**: Limit results to buy/sell.
- **start_time**: Limit results to date range startint at this time.  Use (Get-Date).AddDays(-10) to get results from 10 days ago.
- **end_time**: Limit Results to date range ending in this time. Use (Get-Date).AddDays(-10) to get results from 10 days ago.
- **results_only**: Return only the offers, without the metadata on query. 

#### Examples
```powershell
Get-DexieHistoricalTrades -ticker_id MJO_XCH -type buy -start_time (Get-Date).AddMinutes(-90) -end_time (Get-Date).AddMinutes(0)  

Output:

    success   : True
    ticker_id : MJO_XCH
    pool_id   : d36459170a9f44a430f080cda968e4535d3da892e648e5418fd8a03b33bbd92d
    timestamp : 1723235319527
    trades    : {@{trade_id=6e8b0db35d49d4bed2fa1500683ba8a140452ebf6d19eab51f582f3af4f73ed2; price=0.500073; base_volume=1; target_volume=0.500073; trade_timestamp=1723234626000; type=buy},
                @{trade_id=6f11133c92cdcf9911627bfa27a7b8d96377173c41f06a7ec46ea34dc0aadc7e; price=0.50001; base_volume=1; target_volume=0.50001; trade_timestamp=1723231843000; type=buy}}
```
```powershell
Get-DexiHistoricalTrades -ticker_id DBX_XCH -results_only

Output:

    trade_id        : 2736f7bc559e7a586d990192e823621fd80b9c51220e3651025c8de142fc28e7
    price           : 0.0017391304347826087
    base_volume     : 1725
    target_volume   : 3
    trade_timestamp : 1716271059000
    type            : buy

    trade_id        : d1913a68b2647d206b5a15668733673079c755337b45604683f0d1574e982090
    price           : 0.00174367916303400174
    base_volume     : 1147
    target_volume   : 2
    trade_timestamp : 1716271059000
    type            : buy
```