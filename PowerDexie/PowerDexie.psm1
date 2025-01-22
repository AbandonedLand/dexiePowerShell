function Build-UrlWithParameters {
    <#
        .SYNOPSIS
            Build a url from a hashtable of parameters.
        .DESCRIPTION
            URL builder to help with REST api endpoints that use URL Query parameters.
        .PARAMETER BaseUrl
            The base url of the REST endpoint.  This will be the first part of the website and should begin with https:// or http://.
        .PARAMETER Parameters
            This is a hashtable of key value pairs that represent the url querey parameters for the REST endpoint.
        .EXAMPLE
            Build-UrlWithParameters -BaseUrl "https://api.dexie.space/v1/offers" -Parameters @{"status"=4}
            https://api.dexie.space/v1/offers?status=4
        .EXAMPLE
            Build-UrlWithParameters -BaseUrl "https://api.dexie.space/v1/offers" -Parameters @{"status"=4;"offered"="XCH"}
            https://api.dexie.space/v1/offers?status=4&offered=XCH
        .LINK
            https://dexie.space/api
        .OUTPUTS
            [string]
        .FUNCTIONALITY
            This is a helper function for building uri
            
    #>
    param (
        [string]$BaseUrl,
        [hashtable]$Parameters
    )

    # Validate inputs
    if (-not $BaseUrl) {
        throw "BaseUrl is required."
    }

    if (-not $Parameters) {
        return $BaseUrl
    }

    # Convert hashtable to query string
    $queryString = ($Parameters.GetEnumerator() | ForEach-Object { 
        "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))"
    }) -join "&"

    # Construct the full URL
    if ($BaseUrl -match '\?') {
        # If the base URL already ends with a '?', append parameters directly
        $FullUrl = -join($BaseUrl,"&",$queryString)
    } else {
        # Otherwise, add '?' before the parameters
        $FullUrl = -join($BaseUrl,"?",$queryString)
    }

    return $FullUrl
}

function Get-DexieAssets {
    <#
        .SYNOPSIS
            Retrieve a list of Chia Asset Tokens (CATs) from the dexie asset endpoint.
        .DESCRIPTION
            Query dexie.space for a list of recognized assets on the Chia Blockchain.  
        .OUTPUTS
            [PSCustomObject]@{
                id                  =   Chia asset token id
                code                =   Ticker symbol
                category            =   Token category
                website             =   URL for token
                description         =   Description of token
                liquidity           =   How much is offered on each side of trade { XCH , CAT}
                current_avg_price   =   Value for 1 CAT in XCH 
                volume              =   Daily Volumn in XCH
            }
        .PARAMETER page 
            Results are limited to a certain number per page.  Increase the page to get more results.
        .PARAMETER page_size
            page_size determines how many results are displayed per query.  Max is 100.
        .PARAMETER results_only
            Return only the assets without the metadata of the query.

            [PSCustomObject]@{
                success     =   was the query successful
                count       =   number of items in result
                page        =   current page
                page_size   =   results per page
                assets      =   contains all results for assets in query
            }
        .FUNCTIONALITY 
            This is a way to get a quality list of Chia Asset tokens.  It contains enough information about an asset to be able to 
            look up the token on the your local chia wallet or on other APIs.

        .LINK
            https://dexie.space/assets
        
        .LINK
            More infromation on dexie.space api can be found: https://dexie.space/api

        
        .EXAMPLE
            Get-DexieAssets

            success   : True
            count     : 2203
            page      : 1
            page_size : 50
            assets    : {@{id=a628c1c2c6fcb74d53746157e438e10...}

            .EXAMPLE
            Get-DexieAssets -results_only

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
    #>
    [CmdletBinding()]
    [OutputType([psobject])]
    param (
        [int] $page_size,
        [int] $page,
        [switch]
        $results_only
    )
    # BaseUrl
    $uri = "https://dexie.space/v1/assets"

    # Initialize Paramaters for URL Query Builder
    $parameters = @{}

    if($page_size){
        # Add paramater to hashtable
        $parameters.Add('page_size',$page_size)
    }
    if($page){
        # Add paramater to hashtable
        $parameters.Add('page',$page)
    }
    # Build URI
    $uri = Build-UrlWithParameters -BaseUrl $uri -Parameters $parameters
    
    # Fetch results from API Endpoint
    $results = Invoke-RestMethod -Method Get -Uri $uri -MaximumRetryCount 10 -RetryIntervalSec 5

    if($results_only.IsPresent){
        # Returns only the assets
        return $results.assets
    } else {
        # Return raw results
        return $results
    }
}



function Submit-DexieOffer {
    <#
    .SYNOPSIS
        Send an offer to the dexie.space API Endpoint.
    .DESCRIPTION
        Sends your offer to dexie.space for listing on their exchange.  The offer file is created using the 
        chia wallet.  Offers are a secure way to trade one asset for another on Chia.
    .LINK
        https://dexie.space/api
    .PARAMETER offer
        The text string that represents your offer.  The text will start with 'offer'.
    .PARAMETER drop_only
        If this is set, dexie will only return the offer_id when successful.
    .PARAMETER claim_rewards
        If the offer is part of the liquidity rewards program (https://dexie.space/incentives), dexie will
        automatically send the rewards for providing liquidity to your wallet.  This is especially useful if 
        you use automatically expiring offers.
    .OUTPUTS
        [PSCustomObject]@{
            success : True
            id      : B18UHqaJXBDu8PVBWsY73opqmCszRnT8hEPmL6rYDcYa
            known   : True
            offer   : @{
                    id                : B18UHqaJXBDu8PVBWsY73opqmCszRnT8hEPmL6rYDcYa
                    status            : 4
                    date_found        : 8/6/2022 7:30:21 AM
                    date_completed    : 8/7/2022 12:47:28 AM
                    date_pending      : 8/7/2022 12:46:59 AM
                    date_expiry       : 8/14/2022 12:46:59 AM
                    block_expiry      : 
                    spent_block_index : 2364190
                    price             : 79000
                    offered           : {@{id=a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913; code=SBX; name=Spacebucks; amount=79000}}
                    requested         : {@{id=xch; code=XCH; name=Chia; amount=1}}
                    fees              : 0
            }
        }

    .LINK
        More infromation on dexie.space api can be found: https://dexie.space/api

    .EXAMPLE
    Send-DexieOffer -offer "offer1qqz83wc..."

    success : True
    id      : B18UHqaJXBDu8PVBWsY73opqmCszRnT8hEPmL6rYDcYa
    known   : True
    offer   : @{id=B18UHqaJXBDu8PVBWsY73opqmCszRnT8hEPmL6rYDcYa; status=4; date_found=8/6/2022 7:30:21 AM; date_completed=8/7/2022 12:47:28 AM; date_pending=8/7/2022 12:46:59 AM; date_expiry=8/14/2022 12:46:59 AM; block_expiry=; 
              spent_block_index=2364190; price=79000; offered=System.Object[]; requested=System.Object[]; fees=0}

    #>
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [Parameter(Position=0,mandatory=$true)]
        [string]$offer,
        [switch]
        $drop_only,
        [switch]
        $claim_rewards
    )

    $uri = 'https://api.dexie.space/v1/offers'
    $json = @{
        offer = $offer
    }
    if($drop_only.IsPresent){
        $json.Add('drop_only',$true)
    }
    if($claim_rewards.IsPresent){
        $json.Add('claim_rewards',$true)
    }
    $contentType = 'application/json' 

    $json_offer = $json | ConvertTo-Json

    Invoke-WebRequest -Method POST -body $json_offer -Uri $uri -ContentType $contentType
}
    
function Get-DexieOffers {
    <#
    .SYNOPSIS
        Search for offers posted to dexie.space.
    .DESCRIPTION
        Query dexie.space for offers that exactly what you're looking for.  This powerful
        tool will help you discover offers to complete.  This can also be used for price
        discovery of things listed on Chia.
    .PARAMETER status
        This is the status of the offer.  You can find offers that are:
        'Active','Pending','Cancelling','Cancelled','Completed','Unknown','Expired'
        Multiple choices are allowed.
    .PARAMETER offered
        Only include offers which offer this asset. Request by:
        CODE                (XCH,DBX,SBX)
        ASSET ID            (db1a..., e816...)
        NFT Collection ID   (col1...)
        NFT ID              (nft1...)
    .PARAMETER requested    
        Only include offers which request this asset.
        CODE                (XCH,DBX,SBX)
        ASSET ID            (db1a..., e816...)
        NFT Collection ID   (col1...)
        NFT ID              (nft1...)

    .PARAMETER offered_or_requested
        Search either side of the offer using the same info as requested/offered.
        CODE                (XCH,DBX,SBX)
        ASSET ID            (db1a..., e816...)
        NFT Collection ID   (col1...)
        NFT ID              (nft1...)
    .PARAMETER offered_type
        Limit results to only CAT2 or NFT.
    .PARAMETER requested_type
        Limit results to only CAT2 or NFT.
    .PARAMETER offered_or_requested_type
        Limit results to only CAT2 or NFT.
    .PARAMETER sort
        Sort the results by price,price_desc,date_completed,date_found.
    .PARAMETER compact
        If included, the result will contain just data related to price.  This
        does not include the offer string to take the offer.
    .PARAMETER include_multiple_requested
        Include offers that have multiple assets in the requested parameter.
    .PARAMETER page
        Request a specific page of results
    .PARAMETER page_size
        Set amount of offers per page.  Max of 100.

    .PARAMETER results_only
        Return only the offers, without the metadata on query.        
    .EXAMPLE
    Get-DexieOffers 

    success   : True
    count     : 535623
    page      : 1
    page_size : 20
    offers    : {@{id=948...}

    .EXAMPLE
    Get-DexieOffers -results_only

    id                : 9dJtYToVpcG7UvapnWQH51A4iBWTMRfBXVwrXgfnvEej
    status            : 0
    offer             : offer1qqr83wcuu2rykcmqvpsxygqqd2h6fv0lt2sn8ntyc6t52p2dxeem089j2x7fua0ygjusmd7wlcdkuk3swhc8d6nga5l447u06ml28d0ldrkn7khmlu063ksltjuz7vxl7uu7zhtt50cmdwv32yfh9r7yx2hq7vylhvmrqmn8vrt7uxje45423vjltcf9ep74nm2jm6kuj8ua3f 
                        ffandh443zlxdf7f48vuewuk4k0hj4c6z4x8d2yg9zl08s3y2e7re436m9s8ehtecw8q6dgeglk4cn42ddwjfujcejewkfnhfx2wegynsrjk5pn8ve80vlsc6wewy6gjel0480t00uvsl8kdc0gazrem6ehm0redvkllxjcalxzzssue8rs4ugdxqa3jlhw9h7twhzncmc2d6yw2xmf2 
                        asjcghhj80qw9v8k7lynk3nlae72sh5nef4pe3leytu2t7wl0e5me680mr30lq34eez5awunavns9qeenhq4hkzf9zke3c4l2qxxauv8kjn6a4034l38qvpdnxu4k40gttzcew5wz7qrpfh6z6klsajyc02ef7ug3u3na7apm64x0ukfkm70enawqttqsdqstpmn0prlhqrk0klutlqt 
                        zdtat72fwj0c7kpnw3ltzmcx5a9yrlumd6a64kqcatmtdz92x6q42xtumlc8nnt5clhewrp4mqlyk6tsan9ctne5csz48rc2fgvmll9lddtkacym5fqf23nl6lwpl0l0dhxylghmkewfl4tkremfahhzv4a8kyhnckwewfeululc0utj70l7msjxwv084vqqz3f559alah38wfml8uac 
                        jhpcxwnsj7pa2ltte03ylnzvaky857j9umelx7jjwadg4vd6u40dv9hltdcdjandnl9xmpmfum6alzy2eav87m98ftqet4hp97f2frtkz6z5chake6a884sscays8s675hgf2kpe87uxftvl0rvckac3g3q8t28pal4pjf4uqjclvt4sfnfrm2
    involved_coins    : {0x93355a71f83a710fba766ef68a574c82a0549235ada25e3d74cde348b5758838, 0x840d3530f77b54fda9e9042ce02b5b49787968a98da8a3aa1ea61ffd0b9f01f1}
    date_found        : 8/9/2024 6:44:32 PM
    date_completed    : 
    date_pending      : 
    date_expiry       : 
    block_expiry      : 5763294
    spent_block_index : 
    price             : 15.931
    offered           : {@{id=xch; code=XCH; name=Chia; amount=20}}
    requested         : {@{id=fa4a180ac326e67ea289b869e3448256f6af05721f7cf934cb9901baa6b7a99d; code=wUSDC.b; name=Base warp.green USDC; amount=318.62}}
    fees              : 0
    mempool           : 
    related_offers    : {}
    mod_version       : 2
    trade_id          : 0x08add4531e9c810976736a671d5edffd372833a1c5d792fe5645c331c279c8c1
    known_taker       : 

    ...

    
    .EXAMPLE 
    Get-DexieOffers -status Completed -offered col1aufdw4wm8mph9rdtqljg3nm22k8c6wapuqgfr0mp0anpfhkhn7as6nkpp2 -requested XCH -page_size 2 -page 1 -compact

    success   : True
    count     : 209
    page      : 1
    page_size : 2
    offers    : {@{id=AviVywhpm9MPpFFRvPSPiYBmCiqgKo5k6CmoozH2cqSQ; status=4; involved_coins=System.Object[]; date_found=7/30/2024 11:16:43 AM; date_completed=7/30/2024 2:07:07 PM; date_pending=7/30/2024 2:06:48 PM; date_expiry=;        
                block_expiry=; spent_block_index=5716252; price=0.2; offered=System.Object[]; requested=System.Object[]; fees=0; mempool=; related_offers=System.Object[]; mod_version=2;
                trade_id=0xde4e369991022b5a57861a4e42e47e2b2dc83161eafb4d2bbecf844760b1103d; known_taker=}, @{id=3SuThw2vKzp24nCetXQQjgJXPYNXxk2NyFtCd649TpAH; status=4; involved_coins=System.Object[]; date_found=7/30/2024 11:17:23 AM;   
                date_completed=8/5/2024 2:24:35 PM; date_pending=8/5/2024 2:23:38 PM; date_expiry=; block_expiry=; spent_block_index=5743846; price=0.2; offered=System.Object[]; requested=System.Object[]; fees=0; mempool=;
                related_offers=System.Object[]; mod_version=2; trade_id=0x720c2a1249f68126ec0e5c82f084d7a3441ed7cc742f29fa5187983ee4713f69; known_taker=}}


    .LINK
        More infromation on dexie.space api can be found: https://dexie.space/api

    #>

    [CmdletBinding()]
    param(
        [ValidateSet('Active','Pending','Cancelling','Cancelled','Completed','Unknown','Expired')]
        [string[]]$status,
        [string]$offered,
        [string]$requested,
        [string]$offered_or_requested,
        [ValidateSet('cat','nft')]
        $offered_type,
        [ValidateSet('cat','nft')]
        $requested_type,
        [ValidateSet('cat','nft')]
        $offered_or_requested_type,
        [ValidateSet('price','price_desc','date_completed','date_found')]
        $sort,
        [switch]
        $compact,
        [switch]
        $include_multiple_requested,
        [int]
        $page,
        [int]
        $page_size,
        [switch]
        $results_only
    )
    $uri = "https://api.dexie.space/v1/offers"
    $parameters = @{}

    if($status){
        $status_codes = @{
            Active = 0
            Pending = 1
            Cancelling = 2
            Cancelled = 3
            Completed = 4
            Unknown = 5
            Expired = 6
        }
        foreach($stat in ($status | Select-Object -Unique)){
            $uri = Build-UrlWithParameters -BaseUrl $uri -Parameters @{status=($status_codes.$stat)}
        }
    }
    if($offered){
        $parameters.Add('offered',$offered)
    }
    if($requested){
        $parameters.Add('requested',$requested)
    }
    if($offered_or_requested){
        $parameters.Add('offered_or_requested',$offered_or_requested)
    }
    if($compact.IsPresent){
        $parameters.Add('compact',$true)
    }
    if($include_multiple_requested.IsPresent){
        $parameters.Add('include_multiple_requested',$true)
    }
    if($page){
        $parameters.Add('page',$page)
    }
    if($page_size){
        $parameters.Add('page_size',$page_size)
    }
    $uri = Build-UrlWithParameters -BaseUrl $uri -Parameters $parameters
    $result = Invoke-RestMethod -Method Get -Uri $uri

    if($results_only.IsPresent){
        return $result.offers
    } else {
        return $result
    }
}

function Show-DexieOffer {
    <#
    .SYNOPSIS
        Get the offer details for a specific offer on dexie.space.
    .DESCRIPTION
        Look up an offer on dexie.space.
    .PARAMETER dexie_id
        The dexie_id is a Base58 encoded hash of the offer file or the hash of the spend bundle (a.k.a. trade_id)
    .EXAMPLE
        Show-DexieOffer -id HR7aHbCXsJto7iS9uBkiiGJx6iGySxoNqUGQvrZfnj6B

        success : True
        offer   : @{id=HR7aHbCXsJto7iS9uBkiiGJx6iGySxoNqUGQvrZfnj6B; status=0; ...}
    .EXAMPLE 
        Show-DexieOffer -id HR7aHbCXsJto7iS9uBkiiGJx6iGySxoNqUGQvrZfnj6B -result_only
        
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

        .LINK
        More infromation on dexie.space api can be found: https://dexie.space/api

    #>
    param(
        [Parameter(Position=0,mandatory=$true)]
        [string]$id,
        [switch]
        $result_only
    )

    $uri = -join("https://api.dexie.space/v1/offers/",$id)
    $result = Invoke-RestMethod -Uri $uri -Method Get -MaximumRetryCount 5 -RetryIntervalSec 1

    if($result_only.IsPresent){
        return $result.offer
    } else {
        return $result
    }

}

function Show-DexieOffers {
    <#
    .SYNOPSIS
        Get the offer details for a list of offers on dexie.space.
    .DESCRIPTION
        Look up a list of offers on dexie.space.
    .PARAMETER ids
        The dexie_id is a Base58 encoded hash of the offer file.
    .EXAMPLE

        Show-DexieOffers -ids @("HR7aHbCXsJto7iS9uBkiiGJx6iGySxoNqUGQvrZfnj6B","HR7aHbCXsJto7iS9uBkiiGJx6iGySxoNqUGQvrZfnj6B")

        success : True
        offers  : {@{id=HR7aHbCXsJto7iS9uBkiiGJx6iGySxoNqUGQvrZfnj6B; status=0; ...}
    .EXAMPLE

        Show-DexieOffers -ids @("HR7aHbCXsJto7iS9uBkiiGJx6iGySxoNqUGQvrZfnj6B","AcFmcxPMregpo88srcdQW4FCKDgbVnEEKNA4wS3ydHLh") -result_only

id                : AcFmcxPMregpo88srcdQW4FCKDgbVnEEKNA4wS3ydHLh
status            : 0
date_found        : 1/19/2025 3:14:07 PM
date_completed    : 
maker_puzzle_hash : 0x23d871b75f16693241ca01d421a1a04e77bb42cce1e2cca6a27bc17bd3bf4bba
claimable_rewards : 2.982
trade_id          : 0xaaeedea1b61be691eed187631ce12b82990ddf767dd8989edf92466521244850
mod_version       : 2
rewards           : {@{amount=2.982; code=DBX; id=db1a9020d48d9d4ad22631b66ab4b9ebd3637ef7758ad38881348c5d24c38f20; name=dexie bucks}} 

id                : HR7aHbCXsJto7iS9uBkiiGJx6iGySxoNqUGQvrZfnj6B
status            : 4
date_found        : 8/6/2022 8:28:49 AM
date_completed    : 8/7/2022 1:55:19 PM
maker_puzzle_hash : 0x0150a84dd60158297ef5b8096390fc20de1239239a29acd362675abc239b92b8
claimable_rewards : 0
trade_id          : 0x9228a97feb1047f708a7f563565b1611b7b742e30f2b4a968035019e90ff2959
mod_version       : 1
rewards           : 

.LINK
        More infromation on dexie.space api can be found: https://dexie.space/api

    #>
    [CmdletBinding()]
    param(
        [Parameter(mandatory=$true)]
        [string[]]$ids,
        [switch]
        $result_only
    )
    $json = @{
        ids = $ids
    } | ConvertTo-Json

    $uri = 'https://api.dexie.space/v1/offersBatch'
    $contentType = 'application/json'

    $result = Invoke-RestMethod -Method Post -Uri $uri -Body $json -ContentType $contentType

    if($result_only.IsPresent){
        return $result.offers
    } else {
        return $result
    }

}

function Get-DexiePairs {
    <#
        .SYNOPSIS
            Get a list of all XCH-CAT pairs.
        
        .DESCRIPTION
            Find XCH-Cat pairs on dexie.space that have had at least one XCH trade.
        
        .OUTPUTS
        [array](
            @{
                ticker_id   =   base_target (DBX_XCH)
                base        =   code (DBX)
                target      =   code (XCH)
                pool_id     =   Unique Identifier of Pool (7cd49885b4989bceafbd07cc68b05d9b75e3a43cb2ac85049e4b07ea42e9b9f4)
            }
        )      
        .PARAMETER results_only
            Results only without metadata
        .EXAMPLE 
            Get-DexiePairs

            pairs   : {@{ticker_id=()_XCH; base=();...}
            success : True
        
        .EXAMPLE 
            Get-DexiePairs -results_only
            
            ticker_id               base                target pool_id
            ---------               ----                ------ -------
            ()_XCH                  ()                  XCH    6ad656d5d7c8216da8ce520113073fb0da0fbc6cebc47eb21cf4704d9f80cbc9
            🥔_XCH                  🥔                 XCH    1e458e659657f2f945e90f8e0cc115e1b4f8d190df8151bbe715c9851a5ff219
            $CHIA_XCH               $CHIA               XCH    2f88f387ad7fc024764ab8aa3038da7abf86e302bbed05e918d837dcdd21940b
            0000_XCH                0000                XCH    2d7521213568de1b6b4912ac5867e2dc5767ae69444aec9e7d46e0162343c712
            42_XCH                  42                  XCH    d86bdd3dc1546a1baa023f4573c38b8f6f3507a56f5af06fb3b34e1ab4fb6da2
            ..........
        .LINK
            https://dexie.space/api/prices
        .LINK
            More infromation on dexie.space api can be found: https://dexie.space/api

    #>
    param(
        [switch]
        $results_only
    )
    $results = Invoke-RestMethod -Uri "https://api.dexie.space/v2/prices/pairs" -Method Get

    if($results_only.IsPresent){
        return $results.pairs
    } else {
        return $results
    }
}

function Get-DexieTickers {
    <#
        .SYNOPSIS
            Gather basic trading information on specific ticker_ids.
        
        .DESCRIPTION
            Gather information on ticker_ids.  Ticker_ids can be found using Get-DexiePairs.
        
        .LINK
            https://dexie.space/api/prices
        
        .PARAMETER ticker_id
            The ticker_id is in the BASE_XCH format where BASE is the CAT2 code from Get-DexieAssets.  
            You can also find ticker_ids from Get-DexiePairs.

        .PARAMETER results_only
            Return only the results without the metadata.
        
        .EXAMPLE
            Get-DexieTickers

            success : True
            tickers : {@{ticker_id=()_XCH; base_currency=(); target_currency=XCH; base_id=4bf5122f...}

        .EXAMPLE
            Get-DexieTickers -ticker_id DBX_XCH -results_only

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

    #>

    param(
        [string] $ticker_id,
        [switch] $results_only
    )

    $uri = 'https://api.dexie.space/v2/prices/tickers'
    if($ticker_id){
        $uri = Build-UrlWithParameters -BaseUrl $uri -Parameters @{"ticker_id"=$ticker_id}
    }


    $results = Invoke-RestMethod -Method Get -Uri $uri

    if($results_only.IsPresent){
        $results.tickers
    } else {
        $results
    }
}

function Get-DexieOrderBook {
    <#
        .SYNOPSIS
            Get the current orderbook for trading pair on dexie.space.
        
        .DESCRIPTION
            Pulls the Bid/Ask orderbook from dexie.space. 

        .EXAMPLE
            Get-DexieOrderBook -ticker_id DBX_XCH

            success   : True
            orderbook : @{ticker_id=DBX_XCH; pool_id=7cd4...}

        .EXAMPLE
            Get-DexieOrderBook -ticker_id DBX_XCH -results_only

            ticker_id : DBX_XCH
            pool_id   : 7cd49885b4989bceafbd07cc68b05d9b75e3a43cb2ac85049e4b07ea42e9b9f4
            timestamp : 1723233351153
            bids      : {0.00106097717832543502 4688.131, 0.00104939138576779026 427.2, 0.00104761904761904762 10500, 0.00104333502280790674 394.6…}
            asks      : {0.0011208 5000, 0.00112509736183219611 406.987, 0.00113777777777777778 3600, 0.00115833333333333333 3600…}

        .EXAMPLE 
            Get-DexieOrderBook -ticker_id DBX_XCH -depth 1 -results_only

            ticker_id : DBX_XCH
            pool_id   : 7cd49885b4989bceafbd07cc68b05d9b75e3a43cb2ac85049e4b07ea42e9b9f4
            timestamp : 1723233409842
            bids      : {0.00104939138576779026 427.2}
            asks      : {0.0011208 5000}

        .PARAMETER ticker_id
            The ticker_id is in the BASE_XCH format where BASE is the CAT2 code from Get-DexieAssets.  
            You can also find ticker_ids from Get-DexiePairs.

        .PARAMETER depth 
            How many XCH deep to gather offers for.

        .PARAMETER results_only
            Return only the results without the metadata.

    #>

    param(
        [Parameter(Position=0,mandatory=$true)]
        $ticker_id,
        [int]$depth,
        [switch]$results_only
    )
    $Parameters = @{
        ticker_id = $ticker_id
    }
    if($depth){
        $Parameters.Add("depth",$depth)
    }

    $uri = Build-UrlWithParameters -BaseUrl 'https://api.dexie.space/v2/prices/orderbook' -Parameters $Parameters
    $results = Invoke-RestMethod -Method Get -Uri $uri

    if($results_only.IsPresent){
        return $results.orderbook
    } else {
        return $results
    }

}

function Get-DexieHistoricalTrades {
    <#
    .SYNOPSIS
        Get Historical trades on dexie.space for a given ticker_id.

    .DESCRIPTION
        Query the completed trades on dexie.space for givin ranges.

    .PARAMETER ticker_id
            The ticker_id is in the BASE_XCH format where BASE is the CAT2 code from Get-DexieAssets.  
            You can also find ticker_ids from Get-DexiePairs.

        .PARAMETER limit 
            Limit number of results

        .PARAMETER results_only
            Return only the results without the metadata.

        .PARAMETER type
            Limit results to Buy/Sell

        .PARAMETER start_time
            Limit results to date range startint at this time.  Use (Get-Date).AddDays(-10) to get results from 10 days ago.

        .PARAMETER end_time 
            Limit Results to date range ending in this time. Use (Get-Date).AddDays(-10) to get results from 10 days ago.
        
        .EXAMPLE
            Get-DexieHistoricalTrades -ticker_id MJO_XCH -type buy -start_time (Get-Date).AddMinutes(-90) -end_time (Get-Date).AddMinutes(0)  
            success   : True
            ticker_id : MJO_XCH
            pool_id   : d36459170a9f44a430f080cda968e4535d3da892e648e5418fd8a03b33bbd92d
            timestamp : 1723235319527
            trades    : {@{trade_id=6e8b0db35d49d4bed2fa1500683ba8a140452ebf6d19eab51f582f3af4f73ed2; price=0.500073; base_volume=1; target_volume=0.500073; trade_timestamp=1723234626000; type=buy},
                        @{trade_id=6f11133c92cdcf9911627bfa27a7b8d96377173c41f06a7ec46ea34dc0aadc7e; price=0.50001; base_volume=1; target_volume=0.50001; trade_timestamp=1723231843000; type=buy}}

        .EXAMPLE
            Get-DexiHistoricalTrades -ticker_id DBX_XCH -results_only
            
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
    #>
    param(
        [Parameter(Position=0,mandatory=$true)]
        $ticker_id,
        [ValidateSet("buy","sell")]
        $type,
        [int]$limit,
        [DateTime]$start_time,
        [DateTime]$end_time,
        [switch]$results_only
    )

    $Parameters = @{
        ticker_id = $ticker_id
    }
    if($type){
        $Parameters.Add('type',$type)
    }
    if($limit){
        $Parameters.Add('limit',$limit)
    }
    if($start_time){
        $Parameters.Add('start_time',([Int64](Get-Date -Date $start_time -uFormat %s)*1000))
    }
    if($end_time){
        $Parameters.Add('end_time',([Int64](Get-Date -Date $end_time -uFormat %s)*1000))
    }
    $uri = Build-UrlWithParameters -BaseUrl 'https://api.dexie.space/v2/prices/historical_trades' -Parameters $Parameters
    
    $results = Invoke-RestMethod -Method Get -Uri $uri

    if($results_only.IsPresent){
        return $results.trades
    } else {
        return $results
    }

}

function Show-DexieLiquidityRewards {
    <#
    .SYNOPSIS
        Show the current liquidity rewards on dexie.space.
    .DESCRIPTION
        Show the current liquidity rewards on dexie.space.  This will show the rewards for providing liquidity to the dexie.space exchange.
    .EXAMPLE

        Show-DexieLiquidityRewards -ids @("CxHxbuBUz89Wj8ALmPX4FtUyPFPM1KxXdPqCXReMVd7x",....)

    success offers
    ------- ------
    True {@{id=CxHxbuBUz89Wj8ALmPX4FtUyPFPM1KxXdPqCXReMVd7x; status=0; date_found=1/19/2025 3:14:06 PM; date_completed=; maker_puzzle_hash=0x4f038009275e93d9df1ae2e07695a466313915e9412961234c0465d4adfd4d6a; claimable_rewards=0.163… 

    #>
    param(
        [Parameter(mandatory=$true)]
        [string[]]$ids,
        [switch]$results_only
    )
    $json = @{
        ids = $ids
    } | ConvertTo-Json

    $uri = 'https://api.dexie.space/v1/rewards/check'
    $contentType = 'application/json'

    $result = Invoke-RestMethod -Method Post -Uri $uri -Body $json -ContentType $contentType

    if($results_only.IsPresent){
        return $result.offers
    } else {
        return $result
    }
    

}

function Get-DexieQuote {
    <#
    .SYNOPSIS
        Get a quote for a swap on dexie.space.

    .DESCRIPTION
        Get a quote for a swap on dexie.space.  This will return the quote for the swap.

    .PARAMETER from
        The asset_id or code of the asset to swap from.

    .PARAMETER to
        The asset_id or code of the asset to swap to.

    .PARAMETER from_amount
        The amount in Mojo to swap from.  1 XCH = 1000000000 Mojo.  1 CAT = 1000 Mojo.

    .PARAMETER to_amount
        The amount in Mojo to swap to.  1 XCH = 1000000000 Mojo.  1 CAT = 1000 Mojo.

    .PARAMETER results_only
        Return only the results without the metadata.
    
    .EXAMPLE
        Get-DexieQuote -from XCH -to CAT -from_amount 1000000000 -results_only

        from             : xch
        from_amount      : 1000000000000
        to               : db1a9020d48d9d4ad22631b66ab4b9ebd3637ef7758ad38881348c5d24c38f20
        to_amount        : 197126
        combination_fee  : 100
        suggested_tx_fee : 51791324
    
    .EXAMPLE
        Get-DexieQuote -from XCH -to e0005928763a7253a9c443d76837bdfab312382fc47cab85dad00be23ae4e82f -from_amount 1000000000
    
        success quote
        ------- -----
        True @{from=xch; from_amount=1000000000; to=e0005928763a7253a9c443d76837bdfab312382fc47cab85dad00be23ae4e82f; to_amount=1046108; c…

    .NOTES
        Dexie Swaps have a 1% fee. using this method.

    .LINK
        More infromation on dexie.space api can be found: https://dexie.space/api

    
    
    
    #>
    param(
        [Parameter(mandatory=$true)]
        [string]$from,
        [Parameter(mandatory=$true)]
        [string]$to,
        [UInt64]$from_amount,
        [UInt64]$to_amount,
        [switch]$results_only
    )

    if (-not $from_amount -and -not $to_amount) {
        throw "Either from_amount or to_amount is required."
    }

    $parameters = @{
        from = $from
        to = $to
    }

    if ($from_amount) {
        $parameters.Add('from_amount', $from_amount)
    }

    if ($to_amount) {
        $parameters.Add('to_amount', $to_amount)
    }

    $uri = Build-UrlWithParameters -BaseUrl 'https://api.dexie.space/v1/swap/quote' -Parameters $parameters
    $results = Invoke-RestMethod -Method Get -Uri $uri

    if($results_only.IsPresent){
        return $results.quote
    } else {
        return $results
    }
}

function Submit-DexieSwap {
    <#
    .SYNOPSIS
        Complete a swap on dexie.space.
    .DESCRIPTION
    Complete a swap on dexie.space.  This will take the offer string and complete the swap.
    .NOTES
    Dexie Swaps have a 1% fee.  The fee_destination address is an address owned the the PowerDexie developer.  This allows for part of the trading fee to be sent to the developer as well as dexie.space.

    .PARAMETER offer
        The offer string from the dexie.space offer.
    
    .EXAMPLE
        Complete-DexieSwap -offer offer1qqz83wcsltt6wcmqvpsxygqqwc7hynr6hum6e0mnf72sn7uvvkpt68eyumkhelprk0adeg42nlelk2mpafs8tkhg2qa9qmxpk8znee5xnfq4edmh0ndpyerkh6k2kw3r06amc8mhdfde2ukhre430gyjsvym5x60jsk9afzcujmrpuhcx8lp62k6202ljnklhfm0nu05zdhvht8lkucmew9j2jqqzmy0g0dja7dzmqp570l90q5fe09td3gmns7uvh85advvjalug79jnz8xe8fe2xsaha22acaazhfmt97x0pmglj7mghdy70lfk450ulnpuxalyhvcyc5gdv39wgau5y7d4lqcd4lgcd3lg6d3lg7d3lg7d3llq948usq27uz7d7e7y77xkmf5mcmrwvn2gthfzkxx75q7vu7hqmrw6r8vmfwj8264q42mvn8ruzskxlaklvrfwfyx87ch3j83dt4crhtkcpkrjk6jvreexejdv959tq2ucyx7w4tyvzpn0dzx8f7qch9m0fekynqefu6c8hstrx2uj3haptrg4yhdtxft5xf8qfn5eddwm04pzd59dxjmgk08madexcfrjqsqxx3qake07zcgxhcladasdskneuylkppfp22q7dwrkeketuykp0w8y9a5tkngc4fernrvy68sc5vfqd06e43t03edu5hmh7zlta5vsdqt2dhlzluvkua7lehmegpql9r0vma35478283kultt84zh4u5824ew83f4n8cz23jl7l6pa7tq70c0k34rg00stvazl6q9n0sfkmg3l4frkdlhe7cds4kv6rwv6q6fl0l30ny00mg2z6x4rdlmlc8e4evhhm5cuc0xve772emxk3lhatplzlkag5tl7tucjal70p85ymy52v72tk3ccvcl4xdnvwjm4g77mwf60yt2k50zqmf78l6mlqthzqkakmsw9fvlw29g0mlkat8xvvv7dvml8tkec06a8c6n5tmlfj3d46ujw5kepx6g659ranlsyskdktljmgzxtyp4ze4aar8wjnv7ltl886m2s8v4z6uvnylaeyyu7232t66vu9tutgsdwteg7ctxsxpx9rwgl3e46jamjmv3czld0ame4tflxtr6mwresff0xlxhq7ucz3mwxflc4cthufvn3n6w7pkresuhlh8slv4l0g58m2kd4knkds664ehsn770tjulalw7y30fd6hl3lnnlvlju8m8cxm7274xk43s4lkkc5vh2dav0mgqptjqg7ggwmv9c

        success id                                           offer
        ------- --                                           -----
        True B18UHqaJXBDu8PVBWsY73opqmCszRnT8hEPmL6rYDcYa @{id=B18UHqaJXBDu8PVBWsY73opqmCszRnT8hEPmL6rYDcYa; status=1; date_found=8/6/2022… 


    #>

    param(
        [Parameter(mandatory=$true)]
        [string]$offer
    )

    $json = @{
        offer = $offer
        fee_destination = "xch1gjh6ehqk9m0mvyx4knt3j0zx09nllmech2jeq7cv2lsqgzdh2mnqc5zk2t"
    } | ConvertTo-Json

    $uri = "https://api.dexie.space/v1/swap"
    $contentType = 'application/json'

    $result = Invoke-RestMethod -Method Post -Uri $uri -Body $json -ContentType $contentType
    return $result

}

Export-ModuleMember -Function Get-DexieAssets, Get-DexieOffers, Show-DexieOffer, Show-DexieOffers, Get-DexiePairs, Get-DexieTickers, Get-DexieOrderBook, Get-DexieHistoricalTrades, Show-DexieLiquidityRewards, Get-DexieQuote, Submit-DexieSwap, Submit-DexieOffer