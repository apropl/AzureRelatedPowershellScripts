#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
#$Url = "https://api-test.intadp.sj.se/outbound/kwick/digitalreceipts/v1/?subscription-key=d89af7cf50d14414918c2a7da3659da7"
$Url = "https://api-qa.intadp.sj.se/outbound/kwick/digitalreceipts/v1/?subscription-key=75a821165388409e95c2fbb556c44985"
#$Url = "https://eni00vnnm4cz.x.pipedream.net/"

$Body = '<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<DigitalReceipt MajorVersion="6" MinorVersion="0" FixVersion="0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.nrf-arts.org/IXRetail/namespace/ http://www.nrf-arts.org/IXRetail/namespace/DigitalReceiptV2.0.0.xsd" xmlns="http://www.nrf-arts.org/IXRetail/namespace/">
  <Transaction>
    <BusinessUnit>
      <UnitID Name="SJ AB">556196-5418</UnitID>
      <Address>
        <AddressLine></AddressLine>
        <City>STOCKHOLM</City>
        <PostalCode>11120</PostalCode>
      </Address>
      <Telephone>
        <AreaCode>0771</AreaCode>
        <LocalNumber>757575</LocalNumber>
      </Telephone>
      <Website>www.sj.se</Website>
    </BusinessUnit>
    <Logo>
      <FileName>sj</FileName>
    </Logo>
    <WorkstationID WorkstationLocation="1" TypeCode="POS" Mode="Retail">9</WorkstationID>
    <SequenceNumber>728</SequenceNumber>
    <POSLogDateTime>2020-03-17T14:42:38</POSLogDateTime>
    <OperatorID>LM650W</OperatorID>
    <CurrencyCode>SEK</CurrencyCode>
    <VATRegistrationNumber>556196-5418</VATRegistrationNumber>
    <ReceiptDateTime>2020-03-17T14:42:38</ReceiptDateTime>
    <ReceiptNumber>000000010009007280137</ReceiptNumber>
    <ReceiptImage>
      <ReceiptLine></ReceiptLine>
      <ReceiptLine>*** TEST ***</ReceiptLine>
      <ReceiptLine>------------------------------------------</ReceiptLine>
      <ReceiptLine>Kvitto:   00001-009-00728</ReceiptLine>
      <ReceiptLine>Datum:    2020-03-17 14:42:38</ReceiptLine>
      <ReceiptLine>Org Nr:   556196-5418 kr</ReceiptLine>
      <ReceiptLine>------------------------------------------</ReceiptLine>
      <ReceiptLine></ReceiptLine>
      <ReceiptLine>COCA COLA 33 CL FL.  25,00</ReceiptLine>
      <ReceiptLine></ReceiptLine>
      <ReceiptLine> ===========</ReceiptLine>
      <ReceiptLine>  ATT BETALA ( 1 ARTIKEL ) 25,00</ReceiptLine>
      <ReceiptLine></ReceiptLine>
      <ReceiptLine>  KONTANT 25,00</ReceiptLine>
      <ReceiptLine></ReceiptLine>
      <ReceiptLine>  TILLBAKA 0,00</ReceiptLine>
      <ReceiptLine></ReceiptLine>
      <ReceiptLine></ReceiptLine>
      <ReceiptLine>  Moms (SE)   Belopp      Netto     Brutto</ReceiptLine>
      <ReceiptLine>    12%         2,68      22,32      25,00</ReceiptLine>
      <ReceiptLine></ReceiptLine>
      <ReceiptLine></ReceiptLine>
      <ReceiptLine>9000000010009007280137</ReceiptLine>
      <ReceiptLine></ReceiptLine>
    </ReceiptImage>
    <RetailTransaction>
      <LineItem CancelFlag="false">
        <Sale>
          <ItemID Name="COCA COLA 33 CL FL." Type="GTIN">205</ItemID>
          <Description>COCA COLA 33 CL FL.</Description>
          <RegularSalesUnitPrice>25.0000</RegularSalesUnitPrice>
          <ActualSalesUnitPrice>25.0000</ActualSalesUnitPrice>
          <ExtendedAmount>25.00000</ExtendedAmount>
          <Quantity Units="1.00" UnitOfMeasureCode="EA">1.00000</Quantity>
          <Tax TaxSubType="Standard" TaxType="VAT">
            <Amount>2.67857</Amount>
            <Percent>12.00</Percent>
            <TaxGroupID Name="ArticleGroupCode">04999</TaxGroupID>
          </Tax>
          <LoyaltyAccount>
            <LoyaltyProgram>
              <Points>0</Points>
            </LoyaltyProgram>
          </LoyaltyAccount>
        </Sale>
        <SequenceNumber>1</SequenceNumber>
      </LineItem>
      <LineItem CancelFlag="false">
        <Tender TenderType="Cash">
          <Amount>25.00000</Amount>
        </Tender>
        <SequenceNumber>2</SequenceNumber>
      </LineItem>
      <LineItem CancelFlag="false">
        <Tax TaxType="VAT">
          <TaxableAmount TaxIncludedInTaxableAmountFlag="false">22.32000</TaxableAmount>
          <Amount>2.68000</Amount>
          <Percent>12.00</Percent>
          <TaxExtension GrossAmount="25.0000" xmlns="http://www.etnetwork.org/digitalreceipt-extension/" />
        </Tax>
        <SequenceNumber>3</SequenceNumber>
      </LineItem>
      <Total CurrencyCode="SEK" TotalType="TransactionNetAmount">22.3200</Total>
      <Total CurrencyCode="SEK" TotalType="TransactionGrandAmount">25.00000</Total>
      <Total CurrencyCode="SEK" TotalType="TransactionTaxAmount">2.68000</Total>
      <RetailTransactionExtension xmlns="http://www.etnetwork.org/digitalreceipt-extension/">
        <Barcode Code="9000000010009007280137" Type="I25" />
      </RetailTransactionExtension>
    </RetailTransaction>
  </Transaction>
  <DigID ReceiptNo="000000010009007280137" ETNDigIDPrefix="882863" xmlns="http://www.etnetwork.org/schema/digid/V1.0" />
</DigitalReceipt>'


For ($i=0; $i -lt 10; $i++) {
    "Current iteration: " + ($i)

try
{
    $result = Invoke-WebRequest -ErrorAction Ignore -Method Post -ContentType "application/xml" `
        -Headers @{'Accept' = 'application/xml'; 'X-Processes' = 'kwick'; 'X-Schema-Version' = '2.0.0'; 'Ocp-Apim-Trace' = 'true'; `
        'Authorization' = 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI...'} `
        -Body $Body -Uri $Url
    
    $result.StatusCode
    $result.Headers
    $result.Content
}
catch [System.Net.WebException]
{
    $result = $_.Exception.Response
    $_.ErrorDetails.Message
    $result
}


}
