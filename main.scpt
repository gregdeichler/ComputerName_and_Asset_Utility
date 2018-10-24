with timeout of 3.0E+9 seconds
	set theResultReturned to (display dialog "What is the username?" default answer "" buttons {"Cancel", "Continue"} default button 2 with icon path to resource "applet.icns" in bundle (path to me))
	set textReturned to the text returned of theResultReturned
	set buttonReturned to the button returned of theResultReturned
	if buttonReturned is "Continue" then
		set theAsset to the text returned of (display dialog "What is the Asset Tag?" default answer "" buttons {"Cancel", "Continue"} default button "Continue" with icon path to resource "asset.icns" in bundle (path to me))
		set progress total steps to 4
		set progress description to "Updating Computer Name & Asset"
		set progress additional description to "Setting Computer Name on JAMF"
		set progress completed steps to 1
		do shell script "/usr/local/bin/jamf setComputerName -name \"" & textReturned & "\"" with administrator privileges
		set progress additional description to "Setting Asset Tag on JAMF"
		set progress completed steps to 2
		do shell script "/usr/local/bin/jamf recon -assetTag " & theAsset & "" with administrator privileges
		set progress additional description to "Setting Asset Tag on LANrev"
		set progress completed steps to 3
		do shell script "/usr/bin/plutil -replace UserInfo0 -string " & theAsset & " /Library/Preferences/com.poleposition-sw.lanrev_agent.plist" with administrator privileges
		set progress additional description to "Updating Samanage Record"
		set progress completed steps to 4
		do shell script "/Applications/SamanageAgent.app/Contents/Resources/agent/ruby/bin/ruby /Applications/SamanageAgent.app/Contents/Resources/agent/src/mini_kernel/cmd.rb" with administrator privileges
		do shell script "echo '" & theAsset & "' >/Users/Shared/" & theAsset & ""
		do shell script "chmod 777 /Users/Shared/" & theAsset & ""
		set serialNumber to (do shell script "ioreg -l | grep IOPlatformSerialNumber | cut -d '\"' -f4")
		do shell script "curl -H \"X-Samanage-Authorization: Bearer *******YOUR_SAMANAGE_API_KEY*******\" -H \"Accept: application/vnd.samanage.v1+xml\" -X GET \"https://api.samanage.com/hardwares.xml?&serial_number%5B%5D=" & serialNumber & " \" > /Users/Shared/" & serialNumber & ""
		
		do shell script "grep '<id>' /Users/Shared/" & serialNumber & " | sed \"s@.*<id>\\(.*\\)</id>.*@\\1@\" > /var/tmp/id.dump"
		set id_list to read file "Macintosh HD:Private:var:tmp:id.dump" using delimiter linefeed
		set idNumber to item 1 of id_list
		do shell script "chmod 777 /private/var/tmp/id.dump"
		do shell script "chmod 777 /Users/Shared/" & serialNumber & ""
		do shell script "chmod 777 /Users/Shared/" & theAsset & ""
		do shell script "curl -H \"X-Samanage-Authorization: Bearer *******YOUR_SAMANAGE_API_KEY*******\" -H \"Accept: application/xml\" -H \"Content-Type:text/xml\" -d \"<hardware><tag>" & theAsset & "</tag></hardware>\" -X PUT https://api.samanage.com/hardwares/" & idNumber & ".xml"
		do shell script "/bin/rm -Rf /Library/LaunchDaemons/computername.launch.plist" with administrator privileges
		set progress description to "Unloading & Removing LaunchDaemon"
		do shell script "launchctl unload /Library/LaunchDaemons/computername.launch.plist" with administrator privileges
		set progress description to "The Asset Data Has Been Recorded Successfully!"
		set progress additional description to ""
		display dialog "Computer Name: " & textReturned & " 
Asset Tag: " & theAsset & "" with icon note buttons {"OK"} default button 1
		
	else
		error number -128
	end if
end timeout
