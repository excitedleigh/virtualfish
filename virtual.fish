# VirtualFish
# A Virtualenv wrapper for the Fish Shell based on Doug Hellman's virtualenvwrapper

if not set -q VIRTUALFISH_HOME
	set -g VIRTUALFISH_HOME $HOME/.virtualenvs
end

function acvirtualenv --description "Activate a virtualenv"
	# check arguments
	if [ (count $argv) -lt 1 ]
		echo "You need to specify a virtualenv."
		return 1
	end
	if not [ -d $VIRTUALFISH_HOME/$argv[1] ]
		echo "The virtualenv $argv[1] does not exist."
		echo "You can create it with mkvirtualenv."
		return 2
	end

	#Check if a different env is being used
	if set -q VIRTUAL_ENV
		devirtualenv
	end

	set -gx VIRTUAL_ENV $VIRTUALFISH_HOME/$argv[1]
	set -g _VF_EXTRA_PATH $VIRTUAL_ENV/bin
	set -gx PATH $_VF_EXTRA_PATH $PATH

	# hide PYTHONHOME
	if set -q PYTHONHOME
		set -g _VF_OLD_PYTHONHOME $PYTHONHOME
		set -e PYTHONHOME
	end

	# run postactivate script
    if test -f "$VIRTUAL_ENV/bin/postactivate.fish"
        . "$VIRTUAL_ENV/bin/postactivate.fish"
    end
end

function devirtualenv --description "Deactivate the currently-activated virtualenv"
	# find elements to remove from PATH
	set to_remove
	for i in (seq (count $PATH))
		if contains $PATH[$i] $_VF_EXTRA_PATH
			set to_remove $to_remove $i
		end
	end

	# remove them
	for i in $to_remove
		set -e PATH[$i]
	end

	# restore PYTHONHOME
	if set -q _VF_OLD_PYTHONHOME
		set -gx PYTHONHOME $_VF_OLD_PYTHONHOME
		set -e _VF_OLD_PYTHONHOME
	end

	set -e VIRTUAL_ENV
end

function mkvirtualenv --description "Create a new virtualenv"
	set envname $argv[-1]
	set -e argv[-1]
	virtualenv $argv $VIRTUALFISH_HOME/$envname
	set vestatus $status
	if [ $vestatus -eq 0 ]; and [ -d $VIRTUALFISH_HOME/$envname ]
		acvirtualenv $envname
	else
		echo "Error: The virtualenv wasn't created properly."
		echo "virtualenv returned status $vestatus."
		return 1
	end
end

function rmvirtualenv --description "Delete a virtualenv"
	if not [ (count $argv) -eq 1 ]
		echo "You need to specify exactly one virtualenv."
		return 1
	end
	if set -q VIRTUAL_ENV; and [ $argv[1] = $VIRTUAL_ENV ]
		echo "You can't delete a virtualenv you're currently using."
		return 1
	end
	echo "Removing $VIRTUALFISH_HOME/$argv[1]"
	rm -rf $VIRTUALFISH_HOME/$argv[1]
end

function lsvirtualenv --description "List all of the available virtualenvs"
	pushd $VIRTUALFISH_HOME
	for i in */bin/python
		echo $i
	end | sed "s|/bin/python||"
	popd
end

# Autocomplete
complete -x -c acvirtualenv -a "(lsvirtualenv)"
complete -x -c rmvirtualenv -a "(lsvirtualenv)"
