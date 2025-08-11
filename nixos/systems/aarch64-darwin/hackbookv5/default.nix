# Darwin system configuration for hackbookv5
{ config, pkgs, lib, inputs, ... }:

{
  # Enable Darwin modules
  myDarwinBase.enable = true;
  myDarwinHomebrew.enable = true;
  
  # Set the hostname
  networking.hostName = "hackbookv5";
  networking.computerName = "hackbookv5";
  networking.localHostName = "hackbookv5";

  # System version
  system.stateVersion = 5;

  # User configuration
  users.users.agucova = {
    home = "/Users/agucova";
    shell = pkgs.fish;
  };
}