<h1>ASM Registers</h1>
<h2>For Windows</h2>

<b>Register call order</b> (order that you recieve values from functions):

<ol>
    <li>rcx</li>
    <li>rdx</li>
    <li>r8</li>
    <li>r9</li>
</ol>

<b>Return</b>: rax

<b>All registers</b>:

<ol>
    <li>rax – Return value register; also used for temporary value</li>
    <li>rbx – Callee-saved general-purpose register.</li>
    <li>rcx – 1st argument register; also used as a loop counter.</li>
    <li>rdx – 2nd argument register; used in multiplication/division.</li>
    <li>rsi – Callee-saved; general-purpose (not used for argument passing on Windows x64).</li>
    <li>rdi – Callee-saved; general-purpose.</li>
    <li>rbp – Base pointer; commonly used for stack frame references.</li>
    <li>rsp – Stack pointer; must be 16-byte aligned at call boundaries.</li>
    <li>r8 – 3rd argument register; general-purpose.</li>
    <li>r9 – 4th argument register; general-purpose.</li>
    <li>r10 – Caller-saved; often used as a scratch register.</li>
    <li>r11 – Caller-saved; used internally by the Windows syscall mechanism.</li>
    <li>r12 – Callee-saved general-purpose register.</li>
    <li>r13 – Callee-saved general-purpose register.</li>
    <li>r14 – Callee-saved general-purpose register.<br>SELF STANDARD (for r14 and r15): volatile, should not be trusted to retain prior data after a function call.</li>
    <li>r15 – Callee-saved general-purpose register. Volatile (temporary, see above).</li>
</ol>

<h2>For Linux</h2>

<b>Register call order</b> (order that you recieve values from functions):

<ol>
    <li>rdi</li>
    <li>rsi</li>
    <li>rdx</li>
    <li>rcx</li>
    <li>r8</li>
    <li>r9</li>
</ol>

<b>Return</b>: rax

<b>All registers</b>:

<ol>
    <li>rax – Return value register; also used for syscall numbers and temporary values.</li>
    <li>rbx – Callee-saved general-purpose register; often used to hold persistent values across function calls.</li>
    <li>rcx – 4th argument register; also used as a counter in loops and shift/rotate instructions.</li>
    <li>rdx – 3rd argument register; also used in multiplication/division (high 64 bits of result).</li>
    <li>rsi – 2nd argument register; commonly used as a source pointer in memory/string operations.</li>
    <li>rdi – 1st argument register; commonly used as a destination pointer in memory/string operations.</li>
    <li>rbp – Base pointer; typically used to reference stack frame locals (if a frame pointer is used).</li>
    <li>rsp – Stack pointer; always points to the top of the stack.</li>
    <li>r8 – 5th argument register; general-purpose.</li>
    <li>r9 – 6th argument register; general-purpose.</li>
    <li>r10 – Temporary register; caller-saved.</li>
    <li>r11 – Temporary register; caller-saved.</li>
    <li>r12 – Callee-saved general-purpose register.</li>
    <li>r13 – Callee-saved general-purpose register.</li>
    <li>r14 – Callee-saved general-purpose register.</li>
    <li>r15 – Callee-saved general-purpose register.</li>
</ol>
