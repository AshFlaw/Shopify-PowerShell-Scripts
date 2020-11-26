# Shared Configuration
$apikey = ""
$password = ""

$ShopName = ""
$BatchSize = 250

$CSVProducts = "C:\Reports\Products.csv"
$CSVImages = "C:\Reports\Images.csv"
$CSVVariants = "C:\Reports\Variants.csv"

# Functions
function Get-ShopifyProductCount {
    param (
        $Headers,
        $ShopName
    )
    $uri = "https://$ShopName.myshopify.com/admin/api/2020-10/products/count.json"
    $productsCount = Invoke-WebRequest -Uri $uri -contentType "application/json" -Method Get -Headers $headers | ConvertFrom-Json
    $productsCount.count
}
function Get-RoundNumber {
    param(
        $value, 
        [MidpointRounding]$mode = 'AwayFromZero' 
    )
    [Math]::Round( $value, $mode )
}

$headers = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($apikey+":"+$password))}
# Get the number of products
$CountOfProducts = Get-ShopifyProductCount -Headers $headers -ShopName $ShopName
# Calculate the number of pages
$LoopTotal = Get-RoundNumber -value $($CountOfProducts/$BatchSize)
# Create an array with the number of pages of results it will need to to through
$LoopCounterArray = 1..$LoopTotal
# Build the API path for the first loop
$APIPath = "/admin/api/2019-07/products.json?limit=$BatchSize"
# Build the full path for the first API request
$uri = "https://$ShopName.myshopify.com" +$APIPath
# Variable array to hold the products
foreach ($L in $LoopCounterArray){
    if ($L -eq 1){
        # Get the data and headers from the request
        $response = Invoke-WebRequest -Uri $uri -contentType "application/json" -Method Get -Headers $headers
        # Export the response data to CSV
        ($response | ConvertFrom-Json).products | 
            Select-Object "id","title","vendor","product_type","created_at","handle","updated_at","published_at","template_suffix","published_scope","tags" | 
            Export-CSV $CSVProducts -NoTypeInformation -Append
        ($response | ConvertFrom-Json).products.images | 
            Select-Object "id","product_id","position","created_at","updated_at","alt","width","height","src" | 
            Export-CSV $CSVImages -NoTypeInformation -Append
        ($response | ConvertFrom-Json).products.variants | 
            Select-Object "id","product_id","title","price","sku","position","inventory_policy","compare_at_price","fulfillment_service","inventory_management","option1","option2","option3","created_at","updated_at","taxable","barcode","grams","image_id","weight","weight_unit","inventory_item_id","inventory_quantity","old_inventory_quantity","requires_shipping" | 
            Export-CSV $CSVVariants -NoTypeInformation -Append
        # Wait 0.5 seconds to comply with API rate limiting.
        Start-Sleep -Milliseconds 500
        # Set the uri for the next loop
        $Nexturi = ($($response.Headers.Link) -replace ("<","") -replace (">","") -split (";"))[0]
    }
    else {
        # Get the data and headers from the request
        $response = Invoke-WebRequest -Uri $Nexturi -contentType "application/json" -Method Get -Headers $headers
        # Export the response data to CSV
        ($response | ConvertFrom-Json).products | 
            Select-Object "id","title","vendor","product_type","created_at","handle","updated_at","published_at","template_suffix","published_scope","tags" | 
            Export-CSV $CSVProducts -NoTypeInformation -Append
        ($response | ConvertFrom-Json).products.images | 
            Select-Object "id","product_id","position","created_at","updated_at","alt","width","height","src" | 
            Export-CSV $CSVImages -NoTypeInformation -Append
        ($response | ConvertFrom-Json).products.variants | 
            Select-Object "id","product_id","title","price","sku","position","inventory_policy","compare_at_price","fulfillment_service","inventory_management","option1","option2","option3","created_at","updated_at","taxable","barcode","grams","image_id","weight","weight_unit","inventory_item_id","inventory_quantity","old_inventory_quantity","requires_shipping" | 
            Export-CSV $CSVVariants -NoTypeInformation -Append
        # Wait 0.5 seconds to comply with API rate limiting.
        Start-Sleep -Milliseconds 500
        # Set the uri for the next loop
        $Nexturi = ($($response.Headers.Link) -replace ("<","") -replace (">","") -split (";"))[0]
    }
}
