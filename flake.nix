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
                                            name = "bash-unit-checker" ;
                                            src = ./. ;
                                            buildPhase =
                                                ''
                                                    export OBSERVED=$out &&
                                                        ${ pkgs.writeShellScript "observed" observed } &&
                                                        if [ $( ${ pkgs.coreutils }/bin/cat ${ environment-variable "OBSERVED" } ) == 5d86ec0df0120f534f2c407ac315c362d0cf2619dd0c629240519a8e3915eca04d1ae21783d9ca8560f467fee1745d1ef9e55343723fb48423a4998267e4996c ]
                                                        then
                                                            exit 1
                                                        fi
                                                '' ;
                                            checkPhase =
                                                let
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
                                                            export OBSERVED=$out &&
                                                                export EXPECTED=${ self + "/" + name } &&
                                                                ${ pkgs.bash_unit }/bin/bash_unit ${ pkgs.writeShellScript "test" test }
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
                                                                ${ pkgs.coreutils }/bin/echo ${ pkgs.coreutils }/bin/echo 774cee76b63f8da4a28aac5aa644d7bb3cb5ff12274e43060136cdad41a353ab3b25281124900b9e07c513e815373b6fe025ee647ede2225825de9f6c216f555 > ${ environment-variable "OBSERVED" }
                                                            '' ;
                                                    } ;
                                            success =
                                                lib
                                                    {
                                                        name = "expected" ;
                                                        observed =
                                                            ''
                                                                ${ pkgs.coreutils }/bin/echo ${ pkgs.coreutils }/bin/echo bb882270c0d417368b5d4b08bbdfb27c772137e5b79265422d8d0245ce923f336f4ce661b8b341de1fb2f82fe5b249dbc409b98c45ab6082baf0e983000e93f9 > ${ environment-variable "OBSERVED" }
                                                            '' ;
                                                    } ;
                                              buildSuccess = pkgs.runCommand "build-success" { buildInputs = [ success ]; } ''
                                                if [ -f ${success.outPath} ]; then
                                                  touch $out;
                                                else
                                                  exit 1 ;
                                                fi
                                              '';
buildFailure = pkgs.runCommand "build-failure" { buildInputs = [ failure ]; } ''
  if [ ! -e ${failure} ]; then
    # Failure did not build (this is expected, so we touch $out)
    touch $out;
  else
    # THE REASON THIS DOES NOT WORK AND IT PREVIOUSLY "WORKED" WAS BECAUSE OF THE TRAILING SLASH /
    # -e ${failure}/ looks for a directory named failure and it is not there
    # -e ${failure} looks for any file named failure and it is there
    echo Failure did build, which is unexpected, so we fail the build
    exit 1;
  fi
'';


                                            in
                                                {
                                                    buildSuccess = buildSuccess ;
                                                    # buildFailure = buildFailure ;
                                                } ;
                                                # } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}
