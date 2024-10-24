{
    inputs =
        {
            environment-variable-lib.url = "github:viktordanek/environment-variable" ;
            flake-utils.url = "github:numtide/flake-utils" ;
            nixpkgs.url = "github:NixOs/nixpkgs" ;
            strip-lib.url = "github:viktordanek/strip" ;
        } ;
    outputs =
        { environment-variable-lib , flake-utils , nixpkgs , self , strip-lib } :
            let
                fun =
                    system :
                        let
                            environment-variable = builtins.getAttr system ( builtins.getAttr "lib" environment-variable-lib ) ;
                            lib =
                                {
                                    name ? "expected" ,
                                    observed
                                } :
                                    pkgs.stdenv.mkDerivation
                                        {
                                            name = "bash_unit" ;
                                            src = ./. ;
                                            buildInputs = [ pkgs.makeWrapper ] ;
                                            buildPhase =
                                                let
                                                    bash_unit =
                                                        ''
                                                            ${ pkgs.coreutils }/bin/cat ${ environment-variable "OUT" }/result &&
                                                                exit $( ${ pkgs.coreutils }/bin/cat ${ environment-variable "OUT" }/status )
                                                        '' ;
                                                    test =
                                                        ''
                                                            test_diff ( )
                                                                {
                                                                    assert_equals "" "$( ${ pkgs.diffutils }/bin/diff --brief --recursive ${ environment-variable "EXPECTED" } ${ environment-variable "OBSERVED" } )" "We expect expected to exactly equal observed."
                                                                } &&
                                                                    test_expected_observed ( )
                                                                        {
                                                                            ${ pkgs.findutils }/bin/find ${ environment-variable "EXPECTED" } -type f | while read EXPECTED_FILE
                                                                            do
                                                                                RELATIVE=$( ${ pkgs.coreutils }/bin/echo ${ environment-variable "EXPECTED_FILE" } | ${ pkgs.gnused }/bin/sed -e "s#^${ environment-variable "EXPECTED" }##" ) &&
                                                                                    OBSERVED_FILE=${ environment-variable "OBSERVED" }${ environment-variable "RELATIVE" } &&
                                                                                    if [ ! -f ${ environment-variable "OBSERVED_FILE" } ]
                                                                                    then
                                                                                        fail "The observed file for ${ environment-variable "RELATIVE" } does not exist."
                                                                                    fi &&
                                                                                    assert_equals "$( ${ pkgs.coreutils }/bin/cat ${ environment-variable "EXPECTED_FILE" } )" "$( ${ pkgs.coreutils }/bin/cat ${ environment-variable "OBSERVED_FILE" } )" "The expected file does not equal the observed file for ${ environment-variable "RELATIVE" }."
                                                                            done
                                                                        } &&
                                                                    test_observed_expected ( )
                                                                        {
                                                                            ${ pkgs.findutils }/bin/find ${ environment-variable "OBSERVED" } -type f | while read OBSERVED_FILE
                                                                            do
                                                                                RELATIVE=$( ${ pkgs.coreutils }/bin/echo ${ environment-variable "OBSERVED_FILE" } | ${ pkgs.gnused }/bin/sed -e "s#^${ environment-variable "OBSERVED" }##" ) &&
                                                                                    EXPECTED_FILE=${ environment-variable "EXPECTED" }${ environment-variable "RELATIVE" } &&
                                                                                    if [ ! -f ${ environment-variable "EXPECTED_FILE" } ]
                                                                                    then
                                                                                        fail "The expected file for ${ environment-variable "RELATIVE" } does not exist."
                                                                                    fi &&
                                                                                    assert_equals "$( ${ pkgs.coreutils }/bin/cat ${ environment-variable "EXPECTED_FILE" } )" "$( ${ pkgs.coreutils }/bin/cat ${ environment-variable "OBSERVED_FILE" } )" "The observed file does not equal the expected file for ${ environment-variable "RELATIVE" }."
                                                                            done
                                                                        }
                                                        '' ;
                                                    in
                                                        ''
                                                            ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                export OBSERVED=$out/observed &&
                                                                ${ pkgs.writeShellScript "observed" observed }
                                                                export EXPECTED=${ self + "/" + name } &&
                                                                if ${ pkgs.bash_unit }/bin/bash_unit ${ pkgs.writeShellScript "test" test } > $out/result
                                                                then
                                                                    ${ pkgs.coreutils }/bin/echo ${ environment-variable "?" } > $out/status
                                                                else
                                                                    ${ pkgs.coreutils }/bin/echo ${ environment-variable "?" } > $out/status
                                                                fi &&
                                                                ${ pkgs.coreutils }/bin/mkdir $out/bin &&
                                                                makeWrapper ${ pkgs.writeShellScript "bash_unit" bash_unit } $out/bin/bash_unit --set OUT $out
                                                        '' ;
                                    } ;
                            pkgs = import nixpkgs { system = system ; } ;
                            strip = builtins.getAttr system ( builtins.getAttr "lib" strip-lib ) ;
                            in
                                {
                                    checks =
                                        let
                                            failure =
                                                lib
                                                    {
                                                        name = "expected" ;
                                                        observed =
                                                            ''
                                                                ${ pkgs.coreutils }/bin/echo 774cee76b63f8da4a28aac5aa644d7bb3cb5ff12274e43060136cdad41a353ab3b25281124900b9e07c513e815373b6fe025ee647ede2225825de9f6c216f555 > ${ environment-variable "OBSERVED" }
                                                            '' ;
                                                    } ;
                                            success =
                                                lib
                                                    {
                                                        name = "expected" ;
                                                        observed =
                                                            ''
                                                                ${ pkgs.coreutils }/bin/echo bb882270c0d417368b5d4b08bbdfb27c772137e5b79265422d8d0245ce923f336f4ce661b8b341de1fb2f82fe5b249dbc409b98c45ab6082baf0e983000e93f9 > ${ environment-variable "OBSERVED" }
                                                            '' ;
                                                    } ;
                                                test =
                                                    derivation : status :
                                                        pkgs.runCommand
                                                            "bash_unit"
                                                            { buildInputs = [ derivation ] ; }
                                                            ''
                                                                if [ $( ${ pkgs.coreutils }/bin/cat ${ builtins.toString derivation }/status ) == ${ builtins.toString status } ]
                                                                then
                                                                    ${ pkgs.coreutils }/bin/touch $out
                                                                else
                                                                    ${ pkgs.coreutils }/bin/echo EXPECTED STATUS=${ builtins.toString status } OBSERVED_STATUS=$( ${ pkgs.coreutils }/bin/cat ${ builtins.toString derivation }/status ) &&
                                                                        exit 1
                                                                fi
                                                            '' ;
                                            in
                                                {
                                                    success = test success 0 ;
                                                    # failure = test failure 0 ;
                                                } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}
