{ config, lib, ... }:

lib.mkIf config.flags.profiles.graphical { boot.supportedFilesystems = [ "ntfs" ]; }
