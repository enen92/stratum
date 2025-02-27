# Copyright 2018-present Open Networking Foundation
# SPDX-License-Identifier: Apache-2.0

"""Load dependencies needed for Stratum."""

load(
    "@bazel_tools//tools/build_defs/repo:git.bzl",
    "git_repository",
)
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//bazel:workspace_rule.bzl", "remote_workspace")

P4RUNTIME_VER = "1.3.0"
P4RUNTIME_SHA = "20b187a965fab78df9b8253da14166b8666938a82a2aeea16c6f9abaa934bdcb"

GNMI_COMMIT = "39cb2fffed5c9a84970bde47b3d39c8c716dc17a"
GNMI_SHA = "3701005f28044065608322c179625c8898beadb80c89096b3d8aae1fbac15108"

TAI_COMMIT = "9a673b7310b29c97237b3066a96ea2e43e236cf3"
TAI_SHA = "6c3562906be3a3608f2e0e26c407d6ba4cbc4b587f87b99d811c8530e74edfca"

BF_SDE_PI_VER = {
    "9_2_0": "4546038f5770e84dc0d2bba90f1ee7811c9955df",
    "9_3_0": "4546038f5770e84dc0d2bba90f1ee7811c9955df",
    "9_3_1": "4546038f5770e84dc0d2bba90f1ee7811c9955df",
    "9_4_0": "4546038f5770e84dc0d2bba90f1ee7811c9955df",
    "9_5_0": "4546038f5770e84dc0d2bba90f1ee7811c9955df",
}
GNOI_COMMIT = "437c62e630389aa4547b4f0521d0bca3fb2bf811"
GNOI_SHA = "77d8c271adc22f94a18a5261c28f209370e87a5e615801a4e7e0d09f06da531f"

def stratum_deps():
    # -----------------------------------------------------------------------------
    #        Protobuf + gRPC compiler and external models
    # -----------------------------------------------------------------------------

    if "com_github_grpc_grpc" not in native.existing_rules():
        http_archive(
            name = "com_github_grpc_grpc",
            urls = [
                "https://github.com/grpc/grpc/archive/v1.33.2.tar.gz",
            ],
            strip_prefix = "grpc-1.33.2",
            sha256 = "2060769f2d4b0d3535ba594b2ab614d7f68a492f786ab94b4318788d45e3278a",
        )

    if "com_google_googleapis" not in native.existing_rules():
        http_archive(
            name = "com_google_googleapis",
            urls = ["https://github.com/googleapis/googleapis/archive/a8cd11e2c420a194348839c6490a8a1bef2835d3.zip"],
            strip_prefix = "googleapis-a8cd11e2c420a194348839c6490a8a1bef2835d3",
            sha256 = "bb2b4aa6558e5125a357d829530f2bad932c6f091f0d2faaacfeec185d031ec2",
        )

    if "com_github_p4lang_p4c" not in native.existing_rules():
        # ----- p4c -----
        remote_workspace(
            name = "com_github_p4lang_p4c",
            remote = "https://github.com/p4lang/p4c",
            commit = "43568b75796d68a6424ad22eebeee62f46ccd3fe",
            build_file = "@//bazel:external/p4c.BUILD",
        )

    if "judy" not in native.existing_rules():
        # TODO(Yi): add judy.BUILD to bazel/external/ instead depending on specific one
        http_archive(
            name = "judy",
            build_file = "@com_github_p4lang_PI//bazel/external:judy.BUILD",
            url = "http://archive.ubuntu.com/ubuntu/pool/universe/j/judy/judy_1.0.5.orig.tar.gz",
            strip_prefix = "judy-1.0.5",
            sha256 = "d2704089f85fdb6f2cd7e77be21170ced4b4375c03ef1ad4cf1075bd414a63eb",
        )

    if "com_github_p4lang_p4runtime" not in native.existing_rules():
        http_archive(
            name = "com_github_p4lang_p4runtime",
            urls = ["https://github.com/p4lang/p4runtime/archive/v%s.zip" % P4RUNTIME_VER],
            strip_prefix = "p4runtime-%s/proto" % P4RUNTIME_VER,
            sha256 = P4RUNTIME_SHA,
        )

    if "build_stack_rules_proto" not in native.existing_rules():
        remote_workspace(
            name = "build_stack_rules_proto",
            remote = "https://github.com/stackb/rules_proto",
            commit = "2f4e4f62a3d7a43654d69533faa0652e1c4f5082",
        )

    if "com_github_p4lang_PI" not in native.existing_rules():
        # ----- PI -----
        remote_workspace(
            name = "com_github_p4lang_PI",
            remote = "https://github.com/p4lang/PI.git",
            commit = "35ac4fc80d5a3560d171dc8aa60d104bfa31d37a",
        )

    for sde_ver in BF_SDE_PI_VER:
        dep_name = "com_github_p4lang_PI_bf_" + sde_ver
        pi_commit = BF_SDE_PI_VER[sde_ver]
        if dep_name not in native.existing_rules():
            # ----- PI for Barefoot targets -----
            remote_workspace(
                name = dep_name,
                remote = "https://github.com/p4lang/PI.git",
                commit = pi_commit,
            )

    if "com_github_p4lang_PI_np4" not in native.existing_rules():
        # ----- PI for Netcope targets -----
        remote_workspace(
            name = "com_github_p4lang_PI_np4",
            remote = "https://github.com/craigsdell/PI.git",
            commit = "12be7a96f3d903afdd6cc3095f7d4003242af60b",
        )

    if "com_github_openconfig_gnmi_proto" not in native.existing_rules():
        http_archive(
            name = "com_github_openconfig_gnmi_proto",
            urls = ["https://github.com/bocon13/gnmi/archive/%s.zip" % GNMI_COMMIT],
            sha256 = GNMI_SHA,
            strip_prefix = "gnmi-%s/proto" % GNMI_COMMIT,
            build_file = "@//bazel:external/gnmi.BUILD",
        )

    if "com_github_openconfig_gnoi" not in native.existing_rules():
        http_archive(
            name = "com_github_openconfig_gnoi",
            urls = ["https://github.com/openconfig/gnoi/archive/%s.zip" % GNOI_COMMIT],
            strip_prefix = "gnoi-%s" % GNOI_COMMIT,
            build_file = "@//bazel:external/gnoi.BUILD",
            sha256 = GNOI_SHA,
            patch_cmds = [
                "find . -name *.proto | xargs sed -i'' -e 's#github.com/openconfig/##g'",
                "mkdir -p gnoi",
                "mv bgp cert common diag file interface layer2 mpls otdr system test types wavelength_router gnoi/",
            ],
        )

    if "rules_python" not in native.existing_rules():
        http_archive(
            name = "rules_python",
            url = "https://github.com/bazelbuild/rules_python/releases/download/0.0.1/rules_python-0.0.1.tar.gz",
            sha256 = "aa96a691d3a8177f3215b14b0edc9641787abaaa30363a080165d06ab65e1161",
        )

    if "cython" not in native.existing_rules():
        http_archive(
            name = "cython",
            build_file = "@com_github_grpc_grpc//third_party:cython.BUILD",
            sha256 = "d68138a2381afbdd0876c3cb2a22389043fa01c4badede1228ee073032b07a27",
            strip_prefix = "cython-c2b80d87658a8525ce091cbe146cb7eaa29fed5c",
            urls = [
                "https://github.com/cython/cython/archive/c2b80d87658a8525ce091cbe146cb7eaa29fed5c.tar.gz",
            ],
        )
    if "com_github_openconfig_public" not in native.existing_rules():
        remote_workspace(
            name = "com_github_openconfig_public",
            remote = "https://github.com/openconfig/public",
            commit = "5897507ecdb54453d4457e7dbb0a3d4b7ead4314",
            build_file = "@//bazel:external/ocpublic.BUILD",
        )

    if "com_github_openconfig_hercules" not in native.existing_rules():
        remote_workspace(
            name = "com_github_openconfig_hercules",
            remote = "https://github.com/openconfig/hercules",
            commit = "cd48feeaaa54426df561d8c961d18d344365998b",
            build_file = "@//bazel:external/hercules.BUILD",
        )

    if "com_github_yang_models_yang" not in native.existing_rules():
        remote_workspace(
            name = "com_github_yang_models_yang",
            remote = "https://github.com/YangModels/yang",
            commit = "31daa2507ae507776c23b4d4176b6cdcef2a308c",
            build_file = "@//bazel:external/yang.BUILD",
        )

    if "com_github_nlohmann_json" not in native.existing_rules():
        http_archive(
            name = "com_github_nlohmann_json",
            url = "https://github.com/nlohmann/json/releases/download/v3.7.3/include.zip",
            sha256 = "87b5884741427220d3a33df1363ae0e8b898099fbc59f1c451113f6732891014",
            build_file = "@//bazel:external/json.BUILD",
        )

    # -----------------------------------------------------------------------------
    #        TAI library
    # -----------------------------------------------------------------------------
    if "com_github_telecominfraproject_oopt_tai_taish" not in native.existing_rules():
        http_archive(
            name = "com_github_telecominfraproject_oopt_tai_taish",
            urls = ["https://github.com/Telecominfraproject/oopt-tai/archive/%s.zip" % TAI_COMMIT],
            sha256 = TAI_SHA,
            strip_prefix = "oopt-tai-%s/tools/taish/proto/" % TAI_COMMIT,
            build_file = "@//bazel:external/taish_proto.BUILD",
        )

    # -----------------------------------------------------------------------------
    #        Third party C++ libraries for common
    # -----------------------------------------------------------------------------
    if "com_google_absl" not in native.existing_rules():
        remote_workspace(
            name = "com_google_absl",
            remote = "https://github.com/abseil/abseil-cpp",
            branch = "lts_2021_03_24",
        )

    if "com_github_google_glog" not in native.existing_rules():
        http_archive(
            name = "com_github_google_glog",
            sha256 = "9826ccc86e70f1f1710fc1bb5ba1dc807afa6d3eac1cd694b9dd374761bccf59",
            strip_prefix = "glog-7bba6030c2a0e78c2f169a8a1cf37d899196f053",
            urls = ["https://github.com/google/glog/archive/7bba6030c2a0e78c2f169a8a1cf37d899196f053.zip"],
        )

    if "com_github_gflags_gflags" not in native.existing_rules():
        http_archive(
            name = "com_github_gflags_gflags",
            sha256 = "cfdba0f2f17e8b1ff75c98113d5080d8ec016148426abcc19130864e2952d7bd",
            strip_prefix = "gflags-827c769e5fc98e0f2a34c47cef953cc6328abced",
            urls = ["https://github.com/gflags/gflags/archive/827c769e5fc98e0f2a34c47cef953cc6328abced.zip"],
        )

    if "com_google_googletest" not in native.existing_rules():
        remote_workspace(
            name = "com_google_googletest",
            remote = "https://github.com/google/googletest",
            branch = "3525e3984282c827c7207245b1d4a47f4eaf3c91",
        )

    if "com_googlesource_code_re2" not in native.existing_rules():
        remote_workspace(
            name = "com_googlesource_code_re2",
            remote = "https://github.com/google/re2",
            commit = "be0e1305d264b2cbe1d35db66b8c5107fc2a727e",
        )

    if "com_github_systemd_systemd" not in native.existing_rules():
        remote_workspace(
            name = "com_github_systemd_systemd",
            remote = "https://github.com/systemd/systemd",
            commit = "06e93130b4045db1c75f8de506d2447642de74cf",
            build_file = "@//bazel:external/systemd.BUILD",
        )

    if "com_github_nelhage_rules_boost" not in native.existing_rules():
        git_repository(
            name = "com_github_nelhage_rules_boost",
            commit = "ed844db5990d21b75dc3553c057069f324b3916b",
            remote = "https://github.com/nelhage/rules_boost",
            shallow_since = "1570056263 -0700",
        )

    if "com_github_jbeder_yaml_cpp" not in native.existing_rules():
        git_repository(
            name = "com_github_jbeder_yaml_cpp",
            remote = "https://github.com/jbeder/yaml-cpp.git",
            commit = "de8253fcb075c049c4ad1c466c504bf3cf022f45",
        )

    # -----------------------------------------------------------------------------
    #      Golang specific libraries.
    # -----------------------------------------------------------------------------
    if "bazel_latex" not in native.existing_rules():
        http_archive(
            name = "bazel_latex",
            sha256 = "66ca4240628a4e40cc02d7f77f06b93269dad0068e7a844009fd439e5c55f5a9",
            strip_prefix = "bazel-latex-0.17",
            url = "https://github.com/ProdriveTechnologies/bazel-latex/archive/v0.17.tar.gz",
        )

    # -----------------------------------------------------------------------------
    #        Chipset and Platform specific C/C++ libraries
    # -----------------------------------------------------------------------------
    if "com_github_opennetworkinglab_sdklt" not in native.existing_rules():
        http_archive(
            name = "com_github_opennetworkinglab_sdklt",
            sha256 = "38a59fe2db5122dd76fcbed234c68c59ccfdb68890199b4b891aeb86817713f4",
            urls = ["https://github.com/opennetworkinglab/SDKLT/releases/download/r69/sdklt-4.14.49.tgz"],
            build_file = "@//bazel:external/sdklt.BUILD",
        )

    if "com_github_broadcom_opennsa" not in native.existing_rules():
        http_archive(
            name = "com_github_broadcom_opennsa",
            sha256 = "261a440454015122fbf9ac4cccf018b1c358a641d80690be1f1e972b6265d45c",
            urls = ["https://docs.broadcom.com/docs-and-downloads/csg/opennsa-6.5.19.1.tgz"],
            strip_prefix = "opennsa-6.5.19.1",
            build_file = "@//bazel:external/openNSA.BUILD",
            # TODO(max): This is kind of hacky and should be improved.
            # Each string is a new bash shell, use && to run dependant commands.
            patch_cmds = [
                "wget -qO- https://github.com/opennetworkinglab/OpenNetworkLinux/releases/download/onlpv2-dev-1.0.1/linux-4.14.49-OpenNetworkLinux.tar.xz | tar xz",
                "export CC=gcc CXX=g++ CFLAGS='-Wno-error=unused-result -fno-pie' KERNDIR=$(realpath ./linux-4.14.49-OpenNetworkLinux) && cd src/gpl-modules/systems/linux/user/x86-smp_generic_64-2_6 && make clean -j && make",
            ],
        )

    # -----------------------------------------------------------------------------
    #        P4 testing modules
    # -----------------------------------------------------------------------------

    if "com_github_opennetworkinglab_fabric_p4test" not in native.existing_rules():
        remote_workspace(
            name = "com_github_opennetworkinglab_fabric_p4test",
            remote = "https://github.com/opennetworkinglab/fabric-p4test",
            commit = "ac2b0bf26c4fb91d883492cb85394304cde392c6",
        )

    # -----------------------------------------------------------------------------
    #        Packaging tools
    # -----------------------------------------------------------------------------
    if "rules_pkg" not in native.existing_rules():
        http_archive(
            name = "rules_pkg",
            url = "https://github.com/bazelbuild/rules_pkg/releases/download/0.2.5/rules_pkg-0.2.5.tar.gz",
            sha256 = "352c090cc3d3f9a6b4e676cf42a6047c16824959b438895a76c2989c6d7c246a",
        )
