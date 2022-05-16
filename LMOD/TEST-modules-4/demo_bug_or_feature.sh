echo -e "\nThis demo shows what happens if you use prepend_path (or likely append_path)" \
        "\nin a module to move the directory of the module to the front (or back)" \
        "\nof the MODULEPATH.\n"
          
echo -e "\nThe bug is trigger by setting and exporting TRIGGER_BUG.\n"

echo -e "\nFirst without triggering the bug, look at the output of module spider Appl1:"
unset TRIGGER_BUG
module spider Appl1

echo -e "\nNext setting TRIGGER_BUG to an empty value and exporting," \
        "\nlook again at the output from module spider Appl1:"
export TRIGGER_BUG=
module spider Appl1

echo -e "\nNotice that module spider fails to locate how to load the Appl1 mpodule." \
        "\nThe same also holds for the Appl2/2021 and Appl2/2022 modules."  \
        "\n\nThe offending line is in modules/init-modules/init-cluster/1.0.lua."
