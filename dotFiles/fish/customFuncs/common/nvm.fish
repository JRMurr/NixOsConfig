function nvm-fast
	set -q NVM_DIR ; or set -l NVM_DIR ~/.nvm
	set -l brigand_nvm_fish_path $NVM_DIR/versions/node
	if test (count $argv[1]) -lt 1
		echo 'nvm-fast: at least one argument is required'
	end

	set -l command $argv[1]
	if test $command = 'use'
		set target_version "unknown"
		if test (count $argv) -eq 1
			if test -f .nvmrc
				set target_version (cat .nvmrc)
			else
				echo "Error: No version provided and no .nvmrc found"
				return
			end
		else
			set target_version $argv[2]
		end
		set -l target_version $target_version

		set -l matched_version (bash -c "source $NVM_DIR/nvm.sh --no-use; nvm_version $target_version")

		if test -z $matched_version -o $matched_version = 'N/A'
			echo "No version installed for $target_version, run nvm install $target_version"
			echo "Installed versions: "
			for file in $brigand_nvm_fish_path/v*
				echo ' -' $file
			end
		else
			set -l new_path (string match -ev "$brigand_nvm_fish_path" $PATH)
			if test $matched_version != 'system'
				set new_path $brigand_nvm_fish_path/$matched_version/bin $new_path
			end
			set -gx PATH $new_path
		end
	else
		bash -c "source $NVM_DIR/nvm.sh --no-use; nvm $argv"
	end
end

function nvm
	switch "$FISH_VERSION"
		case 2.0.0 2.1.0 2.1.1 2.1.2 2.2.0 2.2b1 2.3.0 2.3.1 2.3b1 2.3b2 2.4.0 2.4b1 2.5.0 2.5b1
			echo "You need fish 2.6.0 or higher to use fast-nvm-fish." 1>&2
			return 1
	end
	nvm-fast $argv
end

