---
layout: post
title: Java 中 sleep() 与 wait() 方法的区别
---

# 问：简单说说 Java 中 sleep() 与 wait() 方法的区别？
***答：***sleep() 方法使当前线程进入停滞状态（阻塞当前线程），让出 CUP 的使用，目的是不让当前线程独自霸占该进程所获的 CPU 资源。该方法是 Thread 类的静态方法，当在一个 synchronized 块中调用 sleep() 方法时，线程虽然休眠了，但是其占用的锁并没有被释放；当 sleep() 休眠时间期满后，该线程不一定会立即执行，因为其它线程可能正在运行而且没有被调度为放弃执行，除非此线程具有更高的优先级。

wait() 方法是 Object 类的，当一个线程执行到 wait() 方法时就进入到一个和该对象相关的等待池中，同时释放对象的锁（对于 wait(long timeout) 方法来说是暂时释放锁，因为超时时间到后还需要返还对象锁），其他线程可以访问。wait() 使用 notify() 或 notifyAll() 或者指定睡眠时间来唤醒当前等待池中的线程。wait() 必须放在 synchronized 块中使用，否则会在运行时抛出 IllegalMonitorStateException 异常。

由此可以看出它们之间的区别如下：

* sleep() 不释放同步锁，wait() 释放同步锁。

* sleep(milliseconds) 可以用时间指定来使他自动醒过来，如果时间没到则只能调用 interreput() 方法来强行打断（不建议，会抛出 InterruptedException），而 wait() 可以用 notify() 直接唤起。

* sleep() 是 Thread 的静态方法，而 wait() 是 Object 的方法。

* wait()、notify()、notifyAll() 方法只能在同步控制方法或者同步控制块里面使用，而 sleep() 方法可以在任何地方使用。

