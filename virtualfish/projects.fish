if not set -q PROJECT_HOME
    set -g PROJECT_HOME $HOME/projects
end

if not set -q VIRTUALFISH_ACTIVATION_FILE
    set -g VIRTUALFISH_ACTIVATION_FILE .venv
end

function __vf_workon --description "Work on a project"
    if [ (count $argv) -lt 1 ]
        echo "You must specify a project or virtual environment."
        return 1
    end
    # Matches a virtualenv name and possibly a project name
    if [ -d $VIRTUALFISH_HOME/$argv[1] ]
        vf activate $argv[1]
        if [ -d $PROJECT_HOME/$argv[1] ]
            cd $PROJECT_HOME/$argv[1]
        end
        if test -e $VIRTUAL_ENV/.project
            cd (cat $VIRTUAL_ENV/.project)
        end
    # Matches a project name but not a virtualenv name
    else if [ -d $PROJECT_HOME/$argv[1] ]
        set -l project_name $argv[1]
        set -l venv_file "$PROJECT_HOME/$project_name/$VIRTUALFISH_ACTIVATION_FILE"
        if [ -f $venv_file ]
            vf activate (cat $venv_file)
        else
            echo "No virtual environment found."
        end
        cd $PROJECT_HOME/$argv[1]
    else
        echo "No project or virtual environment named $argv[1] exists."
        return 2
    end
end

function __vf_project --description "Create a new project and virtualenv with the name provided"
    set -l options "(fish_opt --short a --required)"
    # kill stderr as argparse throws errors on unknonw parameters
    argparse --name 'vf project' $options -- $argv  ^/dev/null

    if test -z $_flag_a # no porject path given, use plugin standard project path
        set -l project_name $argv[-1]
        set -l project_path "$PROJECT_HOME/$project_name"
        if [ -d $project_path ]
            echo "A project with that name already exists at: $project_path"
            return 2
        else
            vf new $argv
            mkdir -p $project_path
            cd $project_path
        end
    else if vf new $argv # -a $project_path given
        cd $_flag_a
        and pwd >?$VIRTUAL_ENV/.project
    end
end

functions --copy __vf_new __vf__new_projects_original
function __vf_new --wraps=__vf_new
    set -l options (fish_opt --short a --required)
    # kill stderr as argparse throws errors on unknonw parameters
    argparse --name 'vf new' $options -- $argv ^/dev/null
    if __vf__new_projects_original $argv; and test -n $_flag_a
        cd $_flag_a
        and pwd >?$VIRTUAL_ENV/.project
    end
end

function __vf_lsprojects --description "List projects"
    if [ ! -d $PROJECT_HOME ]
        return 2
    end

    pushd $PROJECT_HOME
    for i in *
        if [ -d $i ]
            echo $i
        end
    end
    popd
end

function __vf_cdproject --description "Change working directory to project directory"

    if test -e $VIRTUAL_ENV/.project
        cd (cat $VIRTUAL_ENV/.project)
        return
    end

    if [ ! -d $PROJECT_HOME ]
        return 2
    end
    if set -q VIRTUAL_ENV
        set -l project_name (basename $VIRTUAL_ENV)
        if [ -d $PROJECT_HOME/$project_name ]
            cd $PROJECT_HOME/$project_name
        end
    end
end

if set -q VIRTUALFISH_COMPAT_ALIASES
    function mkproject
        vf project $argv
    end
    function cdproject
        vf cdproject
    end
    function workon
        if not set -q argv[1]
            set_color blue; echo "Projects:"; set_color normal
            vf lsprojects
            set_color blue; echo -e "\nVirtual environments:"; set_color normal
            vf ls
        else
            vf workon $argv[1]
        end
    end

    complete -x -c workon -a "(vf lsprojects)"
end

complete -x -c vf -n '__vfcompletion_using_command workon' -a "(vf lsprojects)"
