------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--               S Y S T E M . B B . T H R E A D S . Q U E U E S            --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2004 The European Space Agency            --
--                     Copyright (C) 2003-2018, AdaCore                     --
--                                                                          --
-- GNARL is free software; you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion. GNARL is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNARL was developed by the GNARL team at Florida State University.       --
-- Extensive contributions were provided by Ada Core Technologies, Inc.     --
--                                                                          --
-- The port of GNARL to bare board targets was initially developed by the   --
-- Real-Time Systems Group at the Technical University of Madrid.           --
--                                                                          --
------------------------------------------------------------------------------

with System.BB.Time;
with System.BB.Board_Support;
with System.Multiprocessors;

package System.BB.Threads.Queues is
   pragma Preelaborate;

   Busy_For_Interrupts : Boolean := False;
   --  Boolean that indicates whether an interrupt is running inside a wrapped
   --  thread. Its value enables/disables First_Thread_Table change

   Busy_For_Handlers : Boolean := False;
   --  Boolean that indicates whether an handler is activated inside a wrapped
   --  thread. Its value enables/disables any context switch until it completes

   use type System.BB.Time.Time;
   package BOSUMU renames System.BB.Board_Support.Multiprocessors;

   ----------------
   -- Ready list --
   ----------------
   procedure Initialize_Log_Table (ID : Integer);
   procedure Add_DM (ID : Integer);
   procedure Add_Runs (ID : Integer);
   procedure Add_Preemption (ID : Integer);
   procedure Print_Log (First_Index : Integer);
   procedure Set_Priority_For_Print (Thread : Thread_Id;
                                    Priority : System.Any_Priority);

   procedure Insert (Thread : Thread_Id) with
   --  Insert the thread into the ready queue. The thread is always inserted
   --  at the tail of its active priority because these are the semantics of
   --  FIFO_Within_Priorities dispatching policy when a task becomes ready to
   --  execute.
   --
   --  There is one case in which the ready queue does not change after the
   --  insertion. It can happen only when there is no ready thread to execute,
   --  in which case the currently running thread was inserted in the queue
   --  (keeping its state as non-runnable). If the state of the thread changes
   --  (after an interrupt), the reinsertion of the thread will not change the
   --  ready queue.

     Pre =>
       Thread /= Null_Thread_Id

         --  Normal insertion

         and then (Thread.State = Runnable

                    --  Insertion in the queue of the thread that was executing
                    --  before (even when it is no longer runnable) because we
                    --  need to have an execution context for the interrupts
                    --  that may arrive.

                    or else First_Thread = Null_Thread_Id),

     Post =>

       --  Insertions in the queue when there is no thread ready to execute
       --  means that there can be no other ready thread.

       (if Thread.State'Old /= Runnable then
         First_Thread = Thread
           and then Running_Thread = Thread
           and then Running_Thread.Next = Null_Thread_Id

        --  Insertions at the tail of its active priority must guarantee that
        --  any thread after this one must have a priority which is strictly
        --  lower than the one just inserted.

        else Thread.Next = Null_Thread_Id
               or else Thread.Active_Priority > Thread.Next.Active_Priority),

     Inline => True;

   procedure Extract (Thread : Thread_Id) with
   --  Remove the thread from the ready queue. We can only extract the one
   --  which is first in the ready queue.

     Pre =>

       --  The only thread that can be extracted from the ready list is the
       --  one that is currently executing (as a result of a delay or a
       --  protected operation).

       Thread = Running_Thread
         and then Thread = First_Thread
         and then Thread.State /= Runnable,

     Post =>
       --  The next thread to execute is the one just next in the ready queue

       First_Thread = Thread.Next'Old
         and then Thread.all.Next = Null_Thread_Id,

     Inline => True;

   procedure Change_Priority (Thread : Thread_Id;
                              Priority : System.Any_Priority;
                              Flag : Boolean);
   --  Move the thread to a new priority within the ready queue
   pragma Inline (Change_Priority);

   --  Pre =>
   --    Thread /= Null_Thread_Id

   --  We can only change the priority of the thread that is currently
   --  executing.

   --   and then Thread = Running_Thread

   --  The new priority can never be lower than the base priority,

   --   and then Priority >= Thread.Base_Priority,

   --  Post =>
   --  Priority has changed

   --    Thread.Active_Priority = Priority

   --  Queue is still ordered and has the same elements (weaken form: has
   --  the same length).

   --    and Queue_Ordered
   --    and Queue_Length = Queue_Length'Old,

   --  function Current_Priority
   --  (CPU_Id : System.Multiprocessors.CPU) return Integer with
   --  Return the active priority of the current thread or
   --  System.Any_Priority'First if no threads are running.

   --  Post =>

   --  When no thread is ready to execute then return the lowest priority

   --     (if Running_Thread_Table (CPU_Id) = Null_Thread_Id
   --       or else Running_Thread_Table (CPU_Id).State /= Runnable
   --      then
   --        Current_Priority'Result = System.Any_Priority'First

   --  Otherwise, return the active priority of the running thread

   --      else
   --        Current_Priority'Result =
   --          Running_Thread_Table (CPU_Id).Active_Priority),

   --  Inline => True;

   procedure Change_Fake_Number_ID
     (Thread       : Thread_Id;
      Fake_Number_ID : Integer);
   pragma Inline (Change_Fake_Number_ID);
   --  Change the fake integer number of the thread

   procedure Change_Is_Sporadic
     (Thread       : Thread_Id;
      Bool : Boolean);

   procedure Change_Relative_Deadline
     (Thread       : Thread_Id;
      Rel_Deadline : System.BB.Deadlines.Relative_Deadline;
      Is_Floor     : Boolean);
   pragma Inline (Change_Relative_Deadline);
   --  Move the thread to a new relative deadline within the ready queue
   --  In addiction updates absolute deadline value of the thread and then
   --  updates its position in the ready queue depending from absolute
   --  deadline value

   --  >>>> DA VALUTARE SE NECESSARIO MANTENERE IL METODO:
   --  Change_Relative_Deadline VARIA GIA' LA DEADLINE RELATIVA E QUELLA
   --  ASSOLUTA RIEFFETTUANDO L'INSERIMENTO IN CODA PER IL THREAD IN OGGETTO
   procedure Change_Absolute_Deadline
       (Thread       : Thread_Id;
        Abs_Deadline : System.BB.Deadlines.Absolute_Deadline);
   pragma Inline (Change_Absolute_Deadline);
   --  Move the thread to a new relative deadline within the ready queue
   --  In addiction updates absolute deadline value of the thread and then
   --  updates its position in the ready queue depending from absolute
   --  deadline value

   --  Removed from Ravenscar EDF version
   --  function Current_Priority
   --    (CPU_Id : System.Multiprocessors.CPU) return System.Any_Priority;
   --  pragma Inline (Current_Priority);
   --  Return the active priority of the current thread or
   --  System.Any_Priority'First if no threads are running.

   function Current_Relative_Deadline
     (CPU_Id : System.Multiprocessors.CPU)
            return System.BB.Deadlines.Relative_Deadline;
   pragma Inline (Current_Relative_Deadline);
   --  Return the active relative deadline of the current thread or
   --  System.BB.Deadline.Relative_Deadline (0) if no threads
   --  are running.

   function Current_Absolute_Deadline
     (CPU_Id : System.Multiprocessors.CPU)
            return System.BB.Deadlines.Absolute_Deadline;
   pragma Inline (Current_Absolute_Deadline);
   --  Return the active absolute deadline of the current thread or
   --  Ada.Deadline.Absolute_Deadline'First if no threads
   --  are running.

   procedure Change_Period
     (Thread       : Thread_Id;
      Period       : System.BB.Time.Time_Span);

   procedure Change_Starting_Time
     (Thread        : Thread_Id;
      Starting_Time : System.BB.Time.Time_Span);

   procedure Change_Release_Jitter
     (Thread        : Thread_Id);

   procedure Update_Jitters
     (Thread      : Thread_Id;
      Response_Jitter : System.BB.Time.Time_Span;
      Release_Jitter : System.BB.Time.Time_Span);

   procedure Yield (Thread : Thread_Id) with
   --  Move the thread to the tail of its current priority

     Pre =>

       --  The only thread that can yield is the one that is currently
       --  executing.

       Thread = Running_Thread
         and then Thread = First_Thread
         and then Thread.State = Runnable,

     Post =>

       Queue_Ordered
         and then

       --  The next thread to execute is the one just next in the ready queue
       --  if it has the same priority of the currently running thread.

         (Thread.Next = Null_Thread_Id
          or else Thread.Next.Active_Priority < Thread.Active_Priority)

       --  In any case, the thread must remain runnable, and no context switch
       --  is possible within this procedure.

       and then Thread = Running_Thread
       and then Thread.all.State = Runnable;

   Running_Thread_Table : array (System.Multiprocessors.CPU) of Thread_Id :=
                            (others => Null_Thread_Id);
   pragma Volatile_Components (Running_Thread_Table);
   pragma Export (Asm, Running_Thread_Table, "__gnat_running_thread_table");
   --  Identifier of the thread that is currently executing in the given CPU.
   --  This shared variable is used by the debugger to know which is the
   --  currently running thread. This variable is exported to be visible in the
   --  assembly code to allow its value to be used when necessary (by the
   --  low-level routines).

   First_Thread_Table : array (System.Multiprocessors.CPU) of Thread_Id :=
                          (others => Null_Thread_Id);
   pragma Volatile_Components (First_Thread_Table);
   pragma Export (Asm, First_Thread_Table, "first_thread_table");
   --  Pointers to the first thread of the priority queue for each CPU. This is
   --  the thread that will be next to execute in the given CPU (if not already
   --  executing). This variable is exported to be visible in the assembly code
   --  to allow its value to be used when necessary (by the low-level
   --  routines).

   function Running_Thread return Thread_Id with
   --  Returns the running thread of the current CPU

     Post => Running_Thread'Result /= Null_Thread_Id,

     Inline => True;

   function First_Thread return Thread_Id with
   --  Returns the first thread in the priority queue of the current CPU

     Inline => True;

   function Context_Switch_Needed return Boolean with
   --  This function returns True if the task (or interrupt handler) that is
   --  executing is no longer the highest priority one. This function can also
   --  be called by the interrupt handlers' epilogue.

     Pre =>
       First_Thread /= Null_Thread_Id
         and then Running_Thread /= Null_Thread_Id,

     Post =>
       Context_Switch_Needed'Result = (First_Thread /= Running_Thread),

     Inline => True,

     Export => True,
     Convention => Asm,
     External_Name => "__gnat_context_switch_needed";

   ----------------
   -- Alarm list --
   ----------------

   procedure Insert_Alarm
     (T        : System.BB.Time.Time;
      Thread   : Thread_Id;
      Is_First : out Boolean) with
   --  This procedure inserts the Thread inside the alarm queue ordered by
   --  Time. If the alarm is the next to be served then the procedure returns
   --  True in the Is_First argument, and False otherwise.

     Pre =>

       --  We can only insert in the alarm queue threads whose state is
       --  Delayed.

       Thread /= Null_Thread_Id
         and then Thread.State = Delayed,

     Post =>

       --  The alarm time is always inserted in the thread descriptor

       Thread.all.Alarm_Time = T

       --  Always inserted by expiration time

       and then (Thread.all.Next_Alarm = Null_Thread_Id
                   or else
                 Thread.all.Alarm_Time <= Thread.all.Next_Alarm.Alarm_Time)

       --  Next alarm can never be later than the currently inserted one

       and then Get_Next_Alarm_Time (Get_CPU (Thread)) <= T

       --  Inserted first in the queue if there is not a more recent alarm

       and then (if Is_First then Get_Next_Alarm_Time (Get_CPU (Thread)) = T);

   function Extract_First_Alarm return Thread_Id with
   --  Extract the first element in the alarm queue and return its identifier

     Post =>

       --  All threads extracted from the alarm queue must be waiting in a
       --  delay statement.

       --  Note: we use AND instead of AND THEN in the conjunctions here
       --  because otherwise the use of OLD in the last test violates the
       --  rule about use of OLD in potentially unevaluated expressions.

       --  Could we instead use pragma Unevaluated_Use_Of_Old (Allow)???

       Extract_First_Alarm'Result.State = Delayed

         --  After extraction the Alarm_Time field is set to Time'Last

         and Extract_First_Alarm'Result.Alarm_Time = System.BB.Time.Time'Last

         --  After extraction the Next_Alarm field is set to Null_Thread_Id

         and Extract_First_Alarm'Result.Next_Alarm = Null_Thread_Id

         --  The extracted thread must be the one with the smallest value of
         --  Alarm_Time.

         and Get_Next_Alarm_Time (BOSUMU.Current_CPU)'Old <=
             Get_Next_Alarm_Time (BOSUMU.Current_CPU),

     Inline => True;

   function Get_Next_Alarm_Time
     (CPU_Id : System.Multiprocessors.CPU) return System.BB.Time.Time;
   pragma Inline (Get_Next_Alarm_Time);
   --  Return the time when the next alarm should be set. This function does
   --  not modify the queue.

   procedure Wakeup_Expired_Alarms (Now : Time.Time) with
   --  Wakeup all expired alarms and set the alarm timer if needed

     Post =>
       Get_Next_Alarm_Time (BOSUMU.Current_CPU) > Now;

   ----------------------------
   -- Global_Interrupt_delay --
   ----------------------------

   Global_Interrupt_Delay : System.BB.Time.Time_Span
     := System.BB.Time.Time_Span (0);

   -----------------
   -- Global_List --
   -----------------

   Global_List : Thread_Id := Null_Thread_Id;
   --  This variable is the starting point of the list containing all threads
   --  in the system. No protection (for concurrent access) is needed for
   --  this variable because task creation is serialized.

   function Queue_Length return Natural with Ghost;
   --  Return the length of the thread list headed by HEAD, following the
   --  next link.

   function Queue_Ordered return Boolean with Ghost;
   --  Return True iff thread list headed by HEAD is correctly ordered by
   --  priority.

end System.BB.Threads.Queues;
