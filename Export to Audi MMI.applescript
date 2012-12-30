# Export to Audi MMI 1.0 by Kip Graham, 2009.  www.dexterparadise.com
#-----------------------------------------------------------#
# SUMMARY:  This is an AppleScript that I originally created because I couldn't find an easy, fast way to export music or a playlist to an SD memory stick in a format playable by my Audi RS4.  The Audi MultiMedia Interface requires songs to be in MP3 format, and all playlists in M3U format.  As such, I created this script to create M3U playlists and to copy or convert songs and place them in organized folders by artist.

# Many thanks go to Doug Adams (dougscripts.com) for posting his iTunes applescripts and making them freely available; there are several lines of code below that I couldn't have completed without his help.

# WORKFLOW:  There are various options when running this script.  They are:
#  1) You can choose between exporting just the songs selected or the entire playlist visible.  If you choose to export the playlist, we also create an M3U playlist file in a given location
#  2) You can choose where you want the music and where you want the playlist saved, and in the process the script calculates a relative link between the two locations (and subfolders)
# 3) You can choose to copy the files directly or convert them to a different format, picking from any of the formats iTunes can convert to.  At this time, DRM-protected files (M4P most commonly) can't be converted, so after the first conversion error we offer the ability to skip M4P automatically.  If a file is already in the desired format, we save time by copying instead.
# 4) After all the conversion (and optionally the playlist generation), we offer the user the option to update or create Genre playlists wherein we add the current list of exported songs to playlists that match the songs' genre.  The application can time out waiting for the user feedback (ie, if you let it run overnight or while you're away), at which point all the songs you've added don't get added to Genre playloists.  I tried to create something that would parse through the folders to recreate the files, but I can't acces the ID3 tags and as such can't get the genre...


tell application "iTunes"
	
	## first we should ask them if they want to export just the songs selected or the whole playlist.  If they pick the full playlist, we can then also create an M3U file.  This also gives us a chance to cancel the script immediately.  We then determine where they want the music (and playlist) to be saved.
	
	# we're going to capture the selection immediately as you can mistakenly click elsewhere in the dialog process.  If they pick playlist we'll overwrite this value later
	set selectedTracks to selection of front window
	
	# these first three are used later to allow the user to automatically skip m4p
	set SKIPM4P to "Not Yet"
	set SKIPYES to "Uh, yeah. Thanks."
	set SKIPNO to "No, I roll control."
	
	set CANCELBUTTON to "Eh, Cancel"
	set SONGSBUTTON to "Just Songs, thanks."
	set PLAYLISTBUTTON to "Full Playlist!"
	
	display dialog "I can export either the selected songs or the whole playlist (along with a playlist M3U file). By default I'll create a folder for each artist." buttons {CANCELBUTTON, SONGSBUTTON, PLAYLISTBUTTON} cancel button 1 default button 3 with title "Songs or Playlist?"
	
	set songsOrPlaylist to button returned of the result
	
	if songsOrPlaylist is SONGSBUTTON and selection of front window is {} then
		display dialog "There are no songs selected.  Please pick either select some songs or choose " & PLAYLISTBUTTON & " next time." buttons {"Oops!"} cancel button 1
	end if
	
	set musicDestination to choose folder with prompt "Where would you like to save the music folders? This can create a lot of folders, so you might want to pick a folder just to contain them all."
	
	if songsOrPlaylist is PLAYLISTBUTTON then
		
		set playlistDestination to choose folder with prompt "Now, where would you like to save the playlist file (M3U)?"
		
		set myPlaylist to the view of browser window 1
		set playlistName to (the name of myPlaylist as text) & ".m3u"
		set selectedTracks to every track in myPlaylist
		
	end if
	
	
	
	
	#While we're asking them stuff, let's determine if the user wants to copy the songs as they are or convert them to a different format (ie, MP3).  We can only convert songs that aren't DRM protected right now.  We're going to convert everything, even if it's already the same file type.  If the file has already been copied there, we obviously assume not to overwrite it, and won't convert on top of it. 
	
	set encoderlist to name of every encoder
	set targetEncoder to (choose from list encoderlist with prompt "Would you like us to convert the music all into one audio file type?" cancel button name "No, thanks." OK button name "Convert to this type." without multiple selections allowed and empty selection allowed) as string
	if targetEncoder is not "false" then
		set targetFormat to format of encoder targetEncoder as string
	end if
	
	
	
	## Now, given the list of tracks we're going to copy, let's create an array of the songs.  We'll include everything we need - Artist, Album, Song Name, Genre, and the location link so we can copy the file.
	## I've had to update this - in order to convert, we need to do the copying at the time of creating the array
	
	set TrackListing to {{"Artist", "Album", "Name", "Genre", "Location", "Duration", "Persistent ID", "Does it Exist Already", "Extension"}}
	
	repeat with eachTrack in selectedTracks
		if class of eachTrack is file track then
			
			# capture all of the song information so we can create the various playlists
			tell eachTrack
				set artistName to artist
				set albumName to album
				set songName to name
				set songGenre to genre
				set songLocation to location
				set songDuration to duration as real
				set songDuration to (round (songDuration) rounding up) as integer
				set persistID to (get persistent ID of eachTrack)
				
				
				# we used to append all the info to the collection here, but I want to capture if it already exists for playlist business.
				set alreadyExists to "No"
				set songExt to name extension of (info for songLocation)
				
			end tell
			
			
			tell application "Finder"
				
				#this is the piece of code that skips the whole copy/conversion process if it's an M4P and the user chose to skip
				if not (songExt is "M4P" and SKIPM4P is SKIPYES) then
					
					# create the artist folder if it doesn't already exist
					if (artistName is not "") and not (folder artistName in musicDestination exists) then
						make new folder at musicDestination with properties {name:artistName as string}
					end if
					
					# here we need to check for either the actual file or the one we'll encode to see if it exists.  If target encoder is "false", we're just copying, so do it
					if targetEncoder is "false" then
						
						try
							# if the song has an artist name it will go into the artist folder, otherwise we'll just put it in the main music folder
							if artistName is not "" then
								
								if not (file (name of (info for songLocation)) in folder artistName in musicDestination exists) then
									duplicate songLocation to folder artistName in musicDestination
								else
									set alreadyExists to "Yes"
								end if
							else
								if not (file (name of (info for songLocation)) in musicDestination exists) then
									duplicate songLocation to musicDestination
								else
									set alreadyExists to "Yes"
								end if
							end if
							
						on error errText number errNum
							display dialog "Oops! We had some sort of problem when we tried to copy the below file over.  Do you have limited access?" & return & return & "Error: " & errText & " (" & errNum & ")" & return & return & songName buttons {"Stop process", "Rats.  Keep going..."} cancel button 1
							set alreadyExists to "Error"
						end try
						
					else
						#we're converting, first see if the target file already exists
						
						# get the clean filename from the eponymous function
						set fileNameExpected to my getCleanFileName(name of (info for songLocation)) & "." & targetFormat
						
						
						# converting takes a while, we're not going to convert if we already have in the past	
						if not (file (fileNameExpected) in folder artistName in musicDestination exists) then
							
							set successfulConversion to my convertToTargetType(targetEncoder, musicDestination, artistName, songName, persistID)
							
							if not successfulConversion then
								# ok, there was some problem with the conversion
								
								# first, let's make sure we don't add lines to the playlists.  
								set alreadyExists to "Error"
								
								# itunes protected files are the most common reason for that, so let's give the user a chance to skip these automatically
								if SKIPM4P is "Not Yet" then
									
									tell application "iTunes"
										display dialog "M4P are the most common file types that we can't convert.  Would you like us to explicitly skip these files so you don't have to keep hitting OK?" buttons {SKIPNO, SKIPYES}
										if button returned of the result is SKIPYES then
											set SKIPM4P to SKIPYES
										else
											set SKIPM4P to SKIPNO
										end if
									end tell
								end if
								
							end if
						else
							set alreadyExists to "Yes"
							
						end if
						
					end if
					
				else
					set alreadyExists to "Skip"
					# end the m4p skipper claus
				end if
			end tell
			
			set the end of TrackListing to {artistName, albumName, songName, songGenre, songLocation, songDuration, persistID, alreadyExists, songExt}
			
		end if
	end repeat
	
	# get rid of the initial header list
	set TrackListing to rest of TrackListing
	
	
	
	
	
	## now, if we're using a playlist, we have to create that file...
	if songsOrPlaylist is PLAYLISTBUTTON then
		
		tell application "Finder"
			try
				set playlistReference to open for access ((POSIX path of playlistDestination) & playlistName) with write permission
				set eof of playlistReference to 0
				#write ((ASCII character 239) & (ASCII character 187) & (ASCII character 191)) to playlistReference starting at eof
				write ("#EXTM3U" & return & return) as Çclass utf8È to playlistReference starting at eof
				
				# for reference, {artistName, albumName, songName, songGenre, songLocation, songDuration, persistID, alreadyExists}
				
				repeat with currentTrack in TrackListing
					set artistName to item 1 of currentTrack
					set albumName to item 2 of currentTrack
					set songName to item 3 of currentTrack
					set songGenre to item 4 of currentTrack
					set songLocation to item 5 of currentTrack
					set songDuration to round (item 6 of currentTrack) rounding as taught in school
					set persistID to item 7 of currentTrack
					set alreadyExists to item 8 of currentTrack
					
					if alreadyExists is "No" then
						write ("#EXTINF: " & songDuration & "," & artistName & " - " & songName & return) as Çclass utf8È to playlistReference starting at eof
						
						set relativeRef to my getRelative(POSIX path of playlistDestination as string, POSIX path of musicDestination & artistName & "/" as string)
						
						if targetEncoder is "false" then
							
							write (relativeRef & name of (info for songLocation) & return) as Çclass utf8È to playlistReference starting at eof
						else
							set fileNameExpected to my getCleanFileName(name of (info for songLocation)) & "." & targetFormat
							
							write (relativeRef & fileNameExpected & return) as Çclass utf8È to playlistReference starting at eof
							
						end if
					end if
				end repeat
				close access playlistReference
			on error errText number errNum
				display dialog "Couldn't access the playlist file - it seems to be open or inaccesible:" & return & errText & " (" & errNum & ")"
				
				close access ((POSIX path of playlistDestination) & playlistName)
			end try
		end tell
		
	end if
	
	
	
	
	set GENRENO to "No, Thanks"
	set GENREYES to "Yes, Please Do."
	
	display dialog "Would you like me to update (or create) the M3U playlist for each genre?  If you already have genre playlists we'll just add to the end, and we'll only add songs that didn't already exists in the music destination." buttons {GENRENO, GENREYES} default button 2 with title "Genre Playlists?"
	
	set GenreAnswer to button returned of the result
	
	
	
	if GenreAnswer is GENREYES then
		
		# create the playlists.  We'll let them pick again in case they want to manage it separately
		
		set playlistDestination to choose folder with prompt "Now, where would you like to save the genre playlist files (M3U)?"
		
		tell application "Finder"
			
			# for reference, {artistName, albumName, songName, songGenre, songLocation, songDuration, persistID, alreadyExists,songExt}
			
			repeat with currentTrack in TrackListing
				set artistName to item 1 of currentTrack
				set albumName to item 2 of currentTrack
				set songName to item 3 of currentTrack
				set songGenre to item 4 of currentTrack
				set songLocation to item 5 of currentTrack
				set songDuration to round (item 6 of currentTrack) rounding as taught in school
				set persistID to item 7 of currentTrack
				set alreadyExists to item 8 of currentTrack
				
				# the assumption is that the user is going to create genre playlists every time they add music.  We thus only will add new music to the genre playliist, which we even tell them.  That being said, if they delete the genre playlist, we'll add the songs that exist too.
				
				if alreadyExists is "No" then
					
					try
						
						if songGenre is "" then
							set songGenre to "Genre Not Defined"
						else
							set songGenre to "Genre - " & songGenre
						end if
						
						#check if the playlist exists first
						if (file (songGenre & ".m3u") in folder playlistDestination exists) then
							
							# a playlist for this genre already exists
							set genreExists to "Yes"
						else
							# there is no playlist for this genre, so we'll create a new one. 
							set genreExists to "No"
						end if
						
						# open the playlist file (create if it doesn't exist)
						set playlistReference to open for access ((POSIX path of playlistDestination) & songGenre & ".m3u") with write permission
						if genreExists is "No" then
							# it's brand new, so add the beginning stuff
							set eof of playlistReference to 0
							#write ((ASCII character 239) & (ASCII character 187) & (ASCII character 191)) to playlistReference starting at eof
							write ("#EXTM3U" & return & return) as Çclass utf8È to playlistReference starting at eof
						end if
						
						# add the song info
						write ("#EXTINF: " & songDuration & "," & artistName & " - " & songName & return) as Çclass utf8È to playlistReference starting at eof
						
						# get the relative ../ reference to the song file
						set relativeRef to my getRelative(POSIX path of playlistDestination as string, POSIX path of musicDestination & artistName & "/" as string)
						
						# if we didn't convert, it's just the song name with existing extension, otherwise we need to clean and append.
						# then, write the actual song reference that allows the song to be played.
						if targetEncoder is "false" then
							
							write (relativeRef & name of (info for songLocation) & return) as Çclass utf8È to playlistReference starting at eof
						else
							
							set fileNameExpected to my getCleanFileName(name of (info for songLocation)) & "." & targetFormat
							
							write (relativeRef & fileNameExpected & return) as Çclass utf8È to playlistReference starting at eof
							
						end if
						
						# our work on this playlist is done, for now.
						close access playlistReference
						
					on error errText number errNum
						display dialog "Couldn't access the [" & songGenre & "] genre file - it seems to be open or inaccesible:" & return & errText & " (" & errNum & ")"
						
						close access ((POSIX path of playlistDestination) & songGenre & ".m3u")
					end try
					
				end if
				
				
			end repeat
			
		end tell
		
	end if
	
	
	
	
	# we're done, let the user know.
	
	display dialog "All Set!" buttons {"Finish"}
	
end tell





# getCleanFileName is a function I wrote to get just the filename without the extension.  Converting takes time, so we want to make sure we don't waste any if the file is already there.  We have to strip out the source extension to check just the name + target encoding extension.  
on getCleanFileName(fullName)
	
	tell application "Finder"
		set default_delimiters to AppleScript's text item delimiters
		set AppleScript's text item delimiters to "."
		
		set fileExtension to the last text item of (fullName)
		set fileNameClean to (text items 1 through -2 of (fullName)) as string
		
		set AppleScript's text item delimiters to default_delimiters
		
		return fileNameClean
		
	end tell
	
end getCleanFileName





on convertToTargetType(myTargetEncoder, myMusicDestination, myArtistName, mySongName, myPersistID)
	
	set success to true
	
	tell application "iTunes"
		
		set existingEncoder to name of current encoder
		set current encoder to encoder myTargetEncoder
		set targetFormat to format of encoder myTargetEncoder as string
		tell (some track of library playlist 1 whose persistent ID is myPersistID)
			set myloc to location
			set songFormat to name extension of (info for (myloc))
		end tell
		
		# it's already converted.  We're just going to copy this puppy because it will cause problems as apple adds a " 1" to a similar named file
		if targetFormat = songFormat then
			tell application "Finder"
				try
					if myArtistName = "" then
						duplicate myloc to myMusicDestination
					else
						duplicate myloc to (folder myArtistName in myMusicDestination)
					end if
				on error errText number errNum
					display dialog "The current file was already in " & targetFormat & " format so we tried copying instead.  There was an error." & return & return & "Error : " & errText & " (" & errNum & ")"
				end try
			end tell
		else
			
			
			try
				with timeout of 1200 seconds
					set errorDialogText to "We had a problem converting the file listed below.  Is it DRM-protected?  (We can't currently convert those)."
					set convertedTrack to item 1 of (convert (some track of library playlist 1 whose persistent ID is myPersistID))
					set convertedLocation to location of convertedTrack
				end timeout
				
				set errorDialogText to "Hmmn... it seems there's something wrong with the location you want to save the songs."
				if myArtistName is not "" then
					set destinationLocation to (quoted form of (POSIX path of myMusicDestination & myArtistName & "/") as string)
				else
					set destinationLocation to (quoted form of (POSIX path of myMusicDestination) as string)
				end if
				
				set errorDialogText to "Oops! We had some sort of problem when we tried to copy the converted file over.  Do you have limited access?"
				do shell script "mv " & (quoted form of POSIX path of convertedLocation) & " " & destinationLocation
				
				set errorDialogText to "Weird, we couldn't delete the temporary track.  Did you mess with it????"
				delete convertedTrack
				
			on error errText number errNum
				
				display dialog errorDialogText & return & return & "Error: " & errText & " (" & errNum & ")" & return & return & mySongName buttons {"Stop process", "Rats.  Keep going..."} cancel button 1
				set success to false
			end try
		end if
		
		set current encoder to encoder existingEncoder
	end tell
	return success
	
end convertToTargetType






# getRelative is a function I wrote from scratch that parses through two POSIX address strings to find a relative path from one to another.
on getRelative(fromRef, toRef)
	
	tell application "Finder"
		
		set fromLength to length of fromRef
		set toLength to length of toRef
		set stillTheSame to true
		set refUp to ""
		set refDown to ""
		
		if fromLength > toLength then
			set greaterLength to fromLength
		else
			set greaterLength to toLength
		end if
		
		repeat with x from 1 to (greaterLength)
			if toLength ³ x then
				if item x of toRef is "/" then
					if stillTheSame is true and item x of toRef = item x of fromRef then
						set refUp to ""
					else
						set stillTheSame to false
						set refUp to refUp & "/"
					end if
				else
					if stillTheSame is true then
						if x > fromLength then
							set stillTheSame to false
						else if item x of toRef is not item x of fromRef then
							set stillTheSame to false
						end if
					end if
					set refUp to refUp & item x of toRef
				end if
			else
				if fromLength > toLength then
					set stillTheSame to false
				end if
			end if
			
			if stillTheSame is false and fromLength ³ x then
				if item x of fromRef is "/" then
					set refDown to refDown & "../"
				end if
			end if
			
		end repeat
		
		return refDown & refUp
	end tell
	
end getRelative
