# vtPowerShell

I'm trying to figure out how to turn most of the essentail things that I do on a Verint/Telligent forum into scripts.

These may or may not ever see the light of day, but I figured I should put them *somewhere*.

I've never written a proper PowerShell Module before, so I'm starting the way I know - with functions to do the things I need.

## Getting Started

To use these functions, you'll need your **username** and an **API key** from your community.
To generate an API key

1. Log into your account, click on your avatar, and then select **Settings**.
2. Scroll down to API Key and click **Manage application API keys**.
3. Under _New Key_ type a name (the name itself is not important) and click **Generate**.
4. Copy and save that API key to a safe location.

**The API Key & Username combination has the same power as your username and password.  Guard these credentials.**

Either clone the repository to a folder or download the functions you wish to use.  Put them all at the same level in the folder.
In the same folder create a `myTest.ps1` file.
This is an example of that file.

``` powershell
# 'Import' the authenticaiton functions
. .\func_Telligent.ps1

$Username = "[Put your username here]"
$ApiKey   = "[Put your API Key here]"

$VtAuthHeader = ConvertTo-VtAuthHeader -Username $Username -ApiKey $ApiKey

$VtCommunity = "[Put your community domain here - include the protocol (http/https) and the trailing slash.]"

# 'Import' the user functions to test connectivity
. .\func_Users.ps1

Get-VtUser -Username $Username -VtCommunity $VtCommunity -VtAuthHeader $VtAuthHeader
```

When you run that file, your results should look something like this:

```text
UserId           : 112233
Username         : MyUsername
EmailAddress     : MyPublicEmail@domain.local
Status           : Approved
ModerationStatus : Unmoderated
CurrentPresence  : Offline
JoinDate         : 2/11/2020 2:59:44 PM
LastLogin        : 4/14/2021 7:51:13 PM
LastVisit        : 4/15/2021 12:56:54 PM
LifetimePoints   : 283319
EmailEnabled     : True
```

If it does, then the functions are working as expected.  You can continue to use the `$VtCommunity` and `$VtAuthHeader` for subsequent calls to other functions.

## Resources I'm Using

- The Verint Community's [REST API Documentation](https://community.telligent.com/community/11/w/api-documentation/64473/rest-api-documentation) is incredibly in depth and well documented.  It's my primary source for most `Invoke-RestMethod` calls.
- Althought I'm not following it step by step, the [Learning PowerShell Toolmaking in a Month of Lunches](https://www.manning.com/books/learn-powershell-toolmaking-in-a-month-of-lunches) has been, and will continue to be my book of reference for this type of work.  Although it 'old' as technology books are concerned (my copy was published in 2013), the methodologies and examples provided are still the best resource I have found.

### Task List

- [ ] Authentication functions
- [ ] Utility functions
- [ ] User Management functions
- [ ] Point Management functions
- [ ] Content Management functions
- [ ] Group Management functions
- [ ] Craft custom types for certain return types
- [ ] Assemble into a module
- [ ] Publish to PSGallery
