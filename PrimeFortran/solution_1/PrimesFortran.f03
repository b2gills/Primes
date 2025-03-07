program primes_fortran
  use iso_fortran_env
  implicit none

  ! All bits are set to 1 for an integer value of -1 as in Fortran there are only signed numbers
  ! and the two's complement is used
  
  integer(int64) , parameter :: all_true = int((-1), kind=int64)
  integer(int64), parameter:: num_possible_upper_limits = 8_int64
  integer(int64):: time_start, time_now, count_rate, count_max
  integer(int64):: sieve_size
  integer(int32):: passes
  integer(kind=int64), dimension (:), allocatable :: array_of_bits ! Mapping for Bit-array

  character(len=255), dimension(1:3) :: command_arguments
  
  
  integer(int64), dimension(1_int64: num_possible_upper_limits):: prime_number_limits
  integer(int32), dimension(1_int32: num_possible_upper_limits):: prime_number_up_to_limit 

  
  prime_number_limits= (/10_int64,&
                         100_int64,&
                         1000_int64,&
                         10000_int64,&
                         100000_int64,&
                         1000000_int64,&
                         10000000_int64,&
                         100000000_int64/)

 
  prime_number_up_to_limit= (/1_int32,&             ! 10
                              25_int32,&            ! 100
                              168_int32,&           ! 1000
                              1229_int32,&          ! 10000
                              9592_int32,&          ! 100000
                              78498_int32,&         ! 1000000
                              664579_int32,&        ! 10000000
                              5761455_int32/)       ! 100000000

  sieve_size = int(1000000, kind = int64)
      
  call allocate_bitfield(sieve_size)

  passes=0

  call system_clock(time_start, count_rate, count_max)

  do while (.true. )

     array_of_bits = all_true   ! sets each element of the array to the same value
     
     call run_sieve
     passes = passes +1_int64
     call system_clock(time_now, count_rate, count_max)
     if ((1.0_real64*(time_now-time_start)) / count_rate .ge. 5.0_real64  ) then        
        exit
     endif
  enddo
  call print_results(.false.,(1.0_real64*(time_now-time_start))/count_rate, passes)    

  
contains

  subroutine allocate_bitfield (n)
    integer(kind=int64) :: n
    if ( mod(n, 64) .eq. 0) then
       allocate (array_of_bits(0:n/64-1))                !integer division
    else
       allocate (array_of_bits(0:n/64))
    endif
    array_of_bits = all_true
  end subroutine allocate_bitfield

  logical function getbit(a,n)
    implicit none
    integer(int64), dimension (0:sieve_size-1) :: a
    integer(int32) :: n
    getbit = btest(a(n/64), mod(n,64) )
  end function getbit

  subroutine setbit_false(n)
    implicit none
    integer(int32) :: n
    array_of_bits(n/64)= ibclr(array_of_bits(n/64), mod(n,64) )
  end subroutine setbit_false


  integer(int64) function count_primes()
    implicit none
    integer(int32):: i
    count_primes = 1_int32
    do i=3, sieve_size-1, 2
       if (getbit(array_of_bits,i))&
            count_primes = count_primes+1
    enddo
  end function count_primes

  logical function validate_results( )
    implicit none
    integer(kind=int64) :: upper_limit_counter
    validate_results = .false.
    
    do upper_limit_counter = 1_int64, num_possible_upper_limits
       if (sieve_size .eq.  prime_number_limits(upper_limit_counter) &
            .and.  count_primes() .eq. prime_number_up_to_limit(upper_limit_counter)) &
            validate_results = .true.
    enddo
  end function validate_results
  
  subroutine print_bit_pattern
    implicit none
    integer(int64) :: j
    do j=0, sieve_size/64
       write(*,'(B64)') array_of_bits(j)
    enddo
    
  end subroutine print_bit_pattern
  
  subroutine print_results(show_results, duration, passes)
    implicit none
    logical, intent(in):: show_results
    real(real64), intent(in) :: duration
    integer(int32),intent(in):: passes
    integer(int32):: count,num,j
    character(len=50) :: raw_string
    character(len=50) :: info_string
    
    integer:: raw_string_counter, info_string_counter
    
    !write(iterations_string,*) passes
    !write(total_time_string,'(F20.6)') duration
    
    count=1
    if (show_results) then
       write(*,'(I16)', advance= 'NO') 2
    endif
    
    do num = 3, sieve_size, 2
       if (getbit(array_of_bits, num)) then
          if (show_results) then 
             write(ERROR_UNIT,'(I10)', advance= 'NO') num          
          endif
          count = count + 1
       endif
    enddo
    
    write(*,'("johandweber_fortran;",I0,";",F0.3,";1" )')  passes, duration
    write(ERROR_UNIT,*)

    if (show_results) then
       write(ERROR_UNIT,'("Passes: ",I10, ", Time: ", F10.2, ", Avg: ",E10.2,&
                          ", Count1: ", I10, ", Count2 :", I10,", Valid :", L  )' ) &
            passes,&
            duration,&
            duration/passes,&
            count,&
            count_primes(),&
            validate_results()
    endif
    
  end subroutine print_results
  
  subroutine run_sieve
    implicit none
    integer(kind = int32) :: factor 
    integer(kind=int32) :: q
    integer(kind=int32) :: num
    
    factor=3_int32
    q=int(sqrt(1.0_real64* sieve_size), kind=int64)
    
    do while (factor .le. q)
       
       do num = factor , sieve_size-1, 2
          if (getbit(array_of_bits, num)) then
             factor=num
             exit
          endif
       enddo

       num=factor**2
       
       do while (num .lt. sieve_size)
          call setbit_false(num)
          num = num + factor*2
       enddo
       factor = factor + 2
    enddo
    

  end subroutine run_sieve

end program primes_fortran
