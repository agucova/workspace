# Darwin system configuration for hackbookv5
{
  ...
}:

{
  # Darwin modules are now automatically applied when imported
  # No need for explicit enables

  # Set the hostname
  networking.hostName = "hackbookv5";
  networking.computerName = "hackbookv5";
  networking.localHostName = "hackbookv5";

  # System version
  system.stateVersion = 5;
}
