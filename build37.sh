#!/bin/sh


#WRL_ENTRYNAV=/bmw117/C13414A/layers
WRL_ENTRYNAV=/bmw117/C13374A/layers
WRL_MMBP=/MM_BASE/arm/layers


/MM_BASE/wrlinux/wrlinux-3.0/wrlinux/configure \
--enable-board=mm_entrynavc2hw \
--with-toolchain-dir=/MM_BASE/arm/toolchain \
--with-host-tools-dir=/MM_BASE/host-tools \
--enable-profile=ivi_base \
--with-layer=\
$WRL_ENTRYNAV/delta_swinteg,\
$WRL_ENTRYNAV/announcementmanager,\
$WRL_ENTRYNAV/audioconnect,\
$WRL_ENTRYNAV/audioroutingmanager,\
$WRL_ENTRYNAV/bmw-hmi,\
$WRL_ENTRYNAV/boot-conf,\
$WRL_ENTRYNAV/cddrv,\
$WRL_ENTRYNAV/cd-eject-server,\
$WRL_ENTRYNAV/cdserver,\
/home/mmes/GITS/ceconn,\
$WRL_ENTRYNAV/cleanup-service,\
$WRL_ENTRYNAV/codingapp,\
$WRL_ENTRYNAV/connectivity,\
$WRL_ENTRYNAV/displayselect,\
$WRL_ENTRYNAV/dlt,\
$WRL_ENTRYNAV/dlt-config,\
$WRL_ENTRYNAV/eq-tool,\
$WRL_ENTRYNAV/filesystem,\
$WRL_ENTRYNAV/fis,\
$WRL_ENTRYNAV/firewall,\
$WRL_ENTRYNAV/flashing-utilities,\
$WRL_ENTRYNAV/gps-src,\
$WRL_ENTRYNAV/harman-share,\
$WRL_ENTRYNAV/hifituner,\
$WRL_ENTRYNAV/housekeeping,\
$WRL_ENTRYNAV/iap,\
$WRL_ENTRYNAV/imc,\
$WRL_ENTRYNAV/ivi-layer-management,\
$WRL_ENTRYNAV/kisu,\
$WRL_ENTRYNAV/lifecycle,\
$WRL_ENTRYNAV/linux-3.1.10,\
$WRL_ENTRYNAV/logging-screenshot,\
$WRL_ENTRYNAV/logistics-manager,\
$WRL_ENTRYNAV/lsrm,\
$WRL_ENTRYNAV/lttng,\
/home/mmes/GITS/multimedia,\
$WRL_ENTRYNAV/navigation,\
$WRL_ENTRYNAV/netconf,\
$WRL_ENTRYNAV/persman,\
$WRL_ENTRYNAV/pia,\
$WRL_ENTRYNAV/speech,\
$WRL_ENTRYNAV/sysinfra,\
$WRL_ENTRYNAV/swtm,\
$WRL_ENTRYNAV/mmbp-isvs,\
$WRL_ENTRYNAV/timemanager,\
$WRL_ENTRYNAV/tcb-test-verbau,\
$WRL_ENTRYNAV/tuner,\
$WRL_ENTRYNAV/uds,\
$WRL_ENTRYNAV/video-in,\
$WRL_ENTRYNAV/videodiagnosis,\
$WRL_ENTRYNAV/videoserver,\
$WRL_ENTRYNAV/vmost,\
$WRL_ENTRYNAV/vtm-client,\
$WRL_ENTRYNAV/xseresampler,\
$WRL_MMBP/wrll-syslib,\
$WRL_MMBP/wrll-mmbp-mm,\
$WRL_MMBP/wrll-mmbp \
--with-template=\
feature/alsajackd,\
feature/AnnouncementManager,\
feature/AudioRoutingManager,\
feature/HifiTuner,\
feature/ceconn,\
feature/eq_tool,\
feature/libimc,\
Connectivity_binaries,\
Navigation_binaries,\
HarmanShare_binaries,\
Speech_binaries,\
DTuner_binaries,\
libuds_App,\
housekeeping_App,\
feature/multimedia,\
feature/vmost-auxin,\
feature/swtmanager,\
lttng,\
delta,\
fis_db_development \
--enable-rpmdatabase=no



