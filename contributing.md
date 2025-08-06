cosmian_kms_cli lives in this order :
is defined within kms/cli
is imported by cosmian_findex_cli (under cosmian-findex git module ) and then REEXPORTED
this repo uses the reexported cosmian_kms_cli

This way, this depency has a single source of truth. Other "ways" do exist, but can induce bugs with any single update.

// TODO
