$FilePath = "C:\Users\kevin.sparenberg\Downloads\Store Orders Report - 20240223-153657.csv"
<#
Original Fields:
 Order ID
 Order Number
 State
 User ID
 Username
 Email
 Ship To
 Address 1
 Address 2
 City
 State/Province
 PostalCode
 Country
 Phone
 Date Created
 Date Assembled
 Assembled By
 Date Shipped
 Shipped By
 Date Fulfilled
 Fulfilled By
 Date Last Modified
 Last Modified By
 Carrier
 Tracking Number
 Total
 Order Items
 Errors
 Fulfillment Details
 Comments
 
Field Mapping:
 Order ID ==> ID [guid]
 Order Number ==> OrderNumber [string]
 State ==> Status [string]
 User ID ==> UserID [int64]
 Username ==> Username [string]
 Email ==> Email [string]
 Ship To ==> AddresssTo
 Address 1 ==> Address1
 Address 2 ==> Address2
 City ==> City
 State/Province ==> StateProvince
 PostalCode ==> PostalCode
 Country ==> Country
 Phone ==> Phone
 Date Created ==> DateCreated [datetime]
 Date Assembled ==> DateAssembled [datetime]
 Assembled By ==> AssembledBy [string]
 Date Shipped ==> DateShipped [datetime]
 Shipped By ==> ShippedBy
 Date Fulfilled ==> DateFulfilled [datetime]
 Fulfilled By ==> FulfilledBy
 Date Last Modified ==> DateModified [datetime]
 Last Modified By ==> LastModifiedBy
 Carrier ==> Carrier
 Tracking Number ==> TrackingNumber
 Total ==> OrderTotal
 Order Items ==> OrderItems [pscustomobject]
 Errors ==> [UNUSED]
 Fulfillment Details ==> FulfilmentInfo [string]
 Comments ==> Comments [string]
#>
$Properties = @(
    @{ Name = "OrderID"; Expression = { [guid]($_.'Order ID') } }
    @{ Name = "OrderNumber"; Expression = { $_.'Order Number' } }
    @{ Name = "Status"; Expression = { $_.'State' } }
    @{ Name = "UserId"; Expression = { [int64]($_.'User ID') } }
    'Username'
    'Email'
    @{ Name = "AddressTo"; Expression = { $_.'Ship To' } }
    @{ Name = "Address1"; Expression = { $_.'Address 1' } }
    @{ Name = "Address2"; Expression = { $_.'Address 2' } }
    'City'
    @{ Name = "StateProvince"; Expression = { $_.'State/Province' } }
    'PostalCode'
    'Country'
    'Phone'
    @{ Name = "DateCreatedUtc"; Expression = { ( [datetime]( $_.'Date Created' ) ).ToUniversalTime() } }
    @{ Name = "DateAssembledUtc"; Expression = { if ( $_.'Date Assembled' -ne 'Thu, 01 Jan 1970 00:00:00 GMT' ) { ( [datetime]( $_.'Date Assembled' ) ).ToUniversalTime() } } }
    @{ Name = "AssembledBy"; Expression = { $_.'Assembled By' } }
    @{ Name = "DateShippedUtc"; Expression = { if ( $_.'Date Shipped' -ne 'Thu, 01 Jan 1970 00:00:00 GMT' ) { ( [datetime]( $_.'Date Shipped' ) ).ToUniversalTime() } } }
    @{ Name = "ShippedBy"; Expression = { $_.'Shipped By' } }
    @{ Name = "DateFulfilledUtc"; Expression = { if ( $_.'Date Fulfilled' -ne 'Thu, 01 Jan 1970 00:00:00 GMT' ) { ( [datetime]( $_.'Date Fulfilled' ) ).ToUniversalTime() } } }
    @{ Name = "DateLastModifiedUtc"; Expression = { if ( $_.'Date Last Modified' -ne 'Thu, 01 Jan 1970 00:00:00 GMT' ) { ( [datetime]( $_.'Date Last Modified' ) ).ToUniversalTime() } } }
    'Carrier'
    @{ Name = "TrackingNumber"; Expression = { $_.'Tracking Number' } }
    @{ Name = "OrderItems"; Expression = { $_.'Order Items' } }
    @{ Name = "OrderTotal"; Expression = { [int64]( $_.'Total' ) } }
    'Errors'
    @{ Name = "FulfillmentInfo"; Expression = { $_.'Fulfillment Details' } }
    'Comments'
)

$Orders = Import-Csv -Path $FilePath | Select-Object -Property $Properties # | Where-Object { $_.DateCreatedUtc -gt '2023-01-01' }

$Orders | Add-Member -MemberType ScriptProperty -Name "TrackingUrl" -Value { switch -wildcard ( $this.Carrier ) {
    "FedEx*" { "https://www.fedex.com/fedextrack/?trknbr=$( $this.TrackingNumber )" }
    "USPS*"  { "https://tools.usps.com/go/TrackConfirmAction_input?origTrackNum=$( $this.TrackingNumber )" }
    "OSM*"   { "https://tools.usps.com/go/TrackConfirmAction_input?origTrackNum=$( $this.TrackingNumber )" }
    "UPS*"   { "http://wwwapps.ups.com/WebTracking/processInputRequest?sort_by=status&error_carried=true&AgreeToTermsAndConditions=yes&tracknums_displayed=1&TypeOfInquiryNumber=T&InquiryNumber1=$( $this.TrackingNumber )" }
}}

$Orders | Add-Member -MemberType ScriptProperty -Name "AddressFull" -Value { ( @"
$( $this.AddressTo )
$( $this.Address1 )
$( $this.Address2 )
$( $this.City ), $( $this.StateProvince ) $( $this.PostalCode )
$( $this.Country )
"@ ) -creplace '(?m)^\s*\r?\n', ''
} -Force
$Orders | Add-Member -MemberType ScriptProperty -Name "Items" -Value {
    $ItemArray = $this.OrderItems.Split(", ")
    $Items = $ItemArray | ForEach-Object {
            [PSCustomObject]@{
                SKU = ( $_.Split("[")[1] ).Split("]")[0]
                Description = ( $_.Split("] ").Split(" (x")[1] )
                Quantity = [int]( ( $_.Split("(x")[-1] ).Split(" @ ")[0] )
                UnitCost = [int64]( $_.Split(" @ ")[-1].Replace('ea)', '') )
            }
    }
    $Items | Add-Member -MemberType ScriptProperty -Name "LineItemCost" -Value { $this.Quantity * $this.UnitCost } -Force
    $Items
} -Force
$Orders | Add-Member -MemberType ScriptProperty -Name "ItemsInOrderDistinct" -Value { $this.Items.Count } -Force
$Orders | Add-Member -MemberType ScriptProperty -Name "ItemsInOrder" -Value { [int]( $this.Items | Measure-Object -Property Quantity -Sum | Select-Object -ExpandProperty Sum ) } -Force

# $Mine = $Orders | Where-Object { $_.UserID -eq 2109 }
#$Mine | Select-Object DateCreated, OrderTotal, ItemsInOrder, ItemsInOrderDistinct

<#
Reports
Order Summary
Items Ordered by People


Carrier Info:
FedEx Url: https://www.fedex.com/fedextrack/?trknbr=<TrackingNumber>
UPS: http://wwwapps.ups.com/WebTracking/processInputRequest?sort_by=status&error_carried=true&tracknums_displayed=1&TypeOfInquiryNumber=T&InquiryNumber1=<TrackingNumber>&AgreeToTermsAndConditions=yes
USPS [OSM]: https://tools.usps.com/go/TrackConfirmAction_input?origTrackNum=<TrackingNumber>


#>
$OrderSummaryReport = $Orders | Select-Object -Property OrderNumber, DateCreatedUtc, UserId, Username, Status, ItemsInOrder, OrderTotal, DateAssembledUtc, DateFulfilledUtc, DateShippedUtc, Carrier, TrackingNumber, TrackingUrl, DateLastModifiedUtc, Comments
$ItemsOrderedReport = $Orders.Items | Select-Object -Property SKU, Description, Quantity, UnitCost, LineItemCost


$TimeTakenFE = Measure-Command -Expression {
ForEach ( $Item in $Orders.Items | Select-Object -Property SKU, Description -Unique | Sort-Object -Property SKU ) {
    [PSCustomObject]@{
        SKU = $Item.SKU
        Description = $Item.Description
        UnitsOrdered = [int64]( $Orders.Items | Where-Object { $_.SKU -eq $Item.SKU } | Measure-Object -Property Quantity -Sum | Select-Object -ExpandProperty Sum )
    }
}
}

$TimeTakenFeO = Measure-Command -Expression {
$Orders.Items | Select-Object -Property SKU, Description -Unique | Sort-Object -Property SKU | ForEach-Object { 
    $SKU = $_.SKU
    [PSCustomObject]@{
        SKU = $_.SKU
        Description = $_.Description
        UnitsOrdered = [int64]( $Orders.Items | Where-Object { $_.SKU -eq $SKU } | Measure-Object -Property Quantity -Sum | Select-Object -ExpandProperty Sum )
    }

}
}

$TimeTakenFE.TotalSeconds
$TimeTakenFeO.TotalSeconds