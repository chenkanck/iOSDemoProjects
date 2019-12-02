#### GCD
a lightweight way to represent units of work that are going to be executed concurrently. You don’t schedule these units of work; the system takes care of scheduling for you. 

Adding dependency among blocks can be a headache. Canceling or suspending a block creates extra work.

#### Operation
 adds a little extra overhead compared to GCD, but you can add dependency among various operations and re-use, cancel or suspend them.
