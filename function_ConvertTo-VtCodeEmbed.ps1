function ConvertTo-VtCodeEmbed {
    [CmdletBinding(DefaultParameterSetName = 'Default', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact = 'Low')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # One or more code strings
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ParameterSetName='Default')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Code,
    
        # Language to use for embeddable
        [Parameter(ParameterSetName='Default')]
        [ValidateSet('bat', 'batchfile', 'c_cpp', 'csharp', 'coffee', 'css', 'd', 'dart', 'diff', 'golang', 'html', 'java', 'javascript', 'json', 'jsp', 'less', 'markdown', 'pascal', 'perl', 'php', 'powershell', 'python', 'ruby', 'sass', 'sql', 'text', 'typescript', 'velocity', 'xml')]
        [string]$Language = 'sql',
    
        # Content Type ID
        [Parameter(ParameterSetName='Default')]
        [AllowNull()]
        [guid]$ContentTypeId = 'dc8ab71f-3b98-42d9-b0f6-e21e02a0f8e2'
    )
    
    Begin {
        <# examples:
        [embed:
        dc8ab71f-3b98-42d9-b0f6-e21e02a0f8e2:
        7cefdf07-aa40-4d9d-b1fc-bc3541eb52db:
        type=sql&
        text=SELECT%20%2A%0D%0AFROM%20TableA%20a%20%7BINNER%20%7C%20%7B%20%7B%20LEFT%20%7C%20RIGHT%20%7C%20FULL%20%7D%20%5B%20OUTER%20%5D%20%7D%20%7D%20TableB%20b%0D%0AON%20a.ColumnName%20%3D%20b.ColumnName%3B
        ]

        [embed:
        dc8ab71f-3b98-42d9-b0f6-e21e02a0f8e2:
        aefc8075-27a2-4574-b792-3e4c54790912:
        type=sql&
        text=SELECT%0D%0A%20%20%20%20h.SalesOrderID%2C%0D%0A%20%20%20%20d.ProductID%0D%0AFROM%20Sales.SalesOrderHeader%20h%0D%0AJOIN%20Sales.SalesOrderDetail%20d%0D%0A%20%20%20%20ON%20h.SalesOrderID%20%3D%20d.SalesOrderID%0D%0AWHERE%20d.ModifiedDate%20%3E%3D%20%2701%2F01%2F2008%27%3B
        ]
        #>
    }
    Process {
        if ($pscmdlet.ShouldProcess("Embeddable", "Convert string")) {
            ForEach ( $c in $Code ) {
                #"[embed:dc8ab71f-3b98-42d9-b0f6-e21e02a0f8e2:$( ( New-Guid ).Guid ):type=$CodeLanguage&text=$( [System.Web.HttpUtility]::UrlEncode($CodeSample.InnerText) )]"
                
                "[embed:$( $ContentTypeId ):$( ( New-Guid ).Guid ):type=$( $Language )&text=$( [System.Web.HttpUtility]::UrlEncode($c) )]"
            }
        }
    }
    End {
        # Nothing to see here.
    }
}
