# audit_tcp_wrappers
#
# TCP Wrappers is a host-based access control system that allows administrators
# to control who has access to various network services based on the IP address
# of the remote end of the connection. TCP Wrappers also provide logging
# information via syslog about both successful and unsuccessful connections.
# Rather than enabling TCP Wrappers for all services with "inetadm -M ...",
# the administrator has the option of enabling TCP Wrappers for individual
# services with "inetadm -m <svcname> tcp_wrappers=TRUE", where <svcname> is
# the name of the specific service that uses TCP Wrappers.
#
# TCP Wrappers provides more granular control over which systems can access
# services which limits the attack vector. The logs show attempted access to
# services from non-authorized systems, which can help identify unauthorized
# access attempts.
#.

audit_tcp_wrappers () {
  if [ "$os_name" = "SunOS" ]; then
    if [ "$os_version" = "10" ] || [ "$os_version" = "11" ]; then
      funct_verbose_message "TCP Wrappers"
      audit_rpc_bind
      for service_name in `inetadm |awk '{print $3}' |grep "^svc"`; do
        funct_command_value inetadm tcp_wrappers TRUE $service_name
      done
    fi
  fi
  if [ "$os_name" = "SunOS" ] || [ "$os_name" = "Linux" ]; then
    funct_verbose_message "Hosts Allow/Deny"
    check_file="/etc/hosts.deny"
    funct_file_value $check_file ALL colon " ALL" hash
    check_file="/etc/hosts.allow"
    funct_file_value $check_file ALL colon " localhost" hash
    funct_file_value $check_file ALL colon " 127.0.0.1" hash
    if [ ! -f "$check_file" ]; then
      for ip_address in `ifconfig -a |grep 'inet addr' |grep -v ':127.' |awk '{print $2}' |cut -f2 -d":"`; do
        netmask=`ifconfig -a |grep '$ip_address' |awk '{print $3}' |cut -f2 -d":"`
        funct_file_value $check_file ALL colon " $ip_address/$netmask" hash
      done
    fi
  fi
  if [ "$os_name" = "Linux" ]; then
    funct_verbose_message "TCP Wrappers"
    if [ "$dist_linux" = "redhat" ] || [ "$dist_linux" = "suse" ]; then
      package_name="tcp_wrappers"
      total=`expr $total + 1`
      log_file="$package_name.log"
      funct_linux_package check $package_name
      if [ "$audit_mode" != 2 ]; then
        echo "Checking:  TCP Wrappers is installed"
      fi
      if [ "$package_name" != "tcp_wrappers" ]; then
        if [ "$audit_mode" = 1 ]; then
          score=`expr $score - 1`
          echo "Warning:   TCP Wrappers is not installed [$score]"
        fi
        if [ "$audit_mode" = 0 ]; then
          echo "Setting:   TCP Wrappers to installed"
          log_file="$work_dir/$log_file"
          echo "Installed $package_name" >> $log_file
          funct_linux_package install $package_name
        fi
      else
        if [ "$audit_mode" = 1 ]; then
          score=`expr $score + 1`
          echo "Secure:    TCP Wrappers is installed [$score]"
        fi
        if [ "$audit_mode" = 2 ]; then
          restore_file="$restore_dir/$log_file"
          funct_linux_package restore $package_name $restore_file
        fi
      fi
    fi
  fi
}