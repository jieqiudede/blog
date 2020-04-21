---
layout: post
title: Looper,ThreadLocal,ThreadLocalMap,MessageQueue
---

# Looper
* 持有Thread, MessageQueue, 静态的ThreadLocal  
* static final ThreadLocal<Looper> sThreadLocal = new ThreadLocal<Looper>();  

```  
private static void prepare(boolean quitAllowed) {
     if (sThreadLocal.get() != null) {
        throw new RuntimeException("Only one Looper may be created per thread");
     }
     sThreadLocal.set(new Looper(quitAllowed));
     }  
```  
* final Thread mThread;  
* final MessageQueue mQueue;  

```  
private Looper(boolean quitAllowed) {
     mQueue = new MessageQueue(quitAllowed);
     mThread = Thread.currentThread();
    }
  
public static void loop() {
        final Looper me = myLooper();   //获得当前的Looper
        if (me == null) {
            throw new RuntimeException("No Looper; Looper.prepare() wasn't called on this thread.");
        }
        
        final MessageQueue queue = me.mQueue;  //获取当前Looper的消息队列
        //......

        for (;;) {
            Message msg = queue.next();  //取出队头的消息
            if (msg == null) {
                // 如果消息为空
                return;
            }
            //......
            try {
                msg.target.dispatchMessage(msg);  //这里target是赋值的hander
                //......
            } finally {
               //......
            }
           //......
            msg.recycleUnchecked();  //回收可能正在使用的消息
        }
    }

```  

# ThreadLocal  
* 只要是当key使用 在ThreadLocalMap中存值，比如存Looper
```
 public void set(T value) {
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t);
        if (map != null)
            map.set(this, value);
        else
            createMap(t, value);
    }  
  
 ThreadLocalMap getMap(Thread t) {
        return t.threadLocals;
    }  

void createMap(Thread t, T firstValue) {
        t.threadLocals = new ThreadLocalMap(this, firstValue);
    }  
```
# ThreadLocalMap  
* 用ThreadLocal生成key 来存值，是Thread的子成员
```
private void set(ThreadLocal<?> key, Object value) {

            // We don't use a fast path as with get() because it is at
            // least as common to use set() to create new entries as
            // it is to replace existing ones, in which case, a fast
            // path would fail more often than not.

            Entry[] tab = table;
            int len = tab.length;
            int i = key.threadLocalHashCode & (len-1);

            for (Entry e = tab[i];
                 e != null;
                 e = tab[i = nextIndex(i, len)]) {
                ThreadLocal<?> k = e.get();

                if (k == key) {
                    e.value = value;
                    return;
                }

                if (k == null) {
                    replaceStaleEntry(key, value, i);
                    return;
                }
            }

            tab[i] = new Entry(key, value);
            int sz = ++size;
            if (!cleanSomeSlots(i, sz) && sz >= threshold)
                rehash();
        }  

ThreadLocalMap(ThreadLocal<?> firstKey, Object firstValue) {
            table = new Entry[INITIAL_CAPACITY];
            int i = firstKey.threadLocalHashCode & (INITIAL_CAPACITY - 1);
            table[i] = new Entry(firstKey, firstValue);
            size = 1;
            setThreshold(INITIAL_CAPACITY);
        }  

static class Entry extends WeakReference<ThreadLocal<?>> {
            /** The value associated with this ThreadLocal. */
            Object value;

            Entry(ThreadLocal<?> k, Object v) {
                super(k);
                value = v;
            }
        }  
```
# MessageQueue  
* 内部有一个enqueueMessage(Message msg, long when),这里是用单项链表存储的Message,根据when排序，优先比较队列中排在最后的那个Message,when值晓得派在最后，也就是先出。如果不满足 就会while循环队列查找when大的然后插入(这里不能说是队列，是一个单项链表，只是操作类似队列，按照“先进先出”的原则存放消息。存放并非实际意义的保存，而是将Message对象以链表的方式串联起来的)  

# Message  
* 当我们每次需要创建Message的时候，从缓存池中获取，如果缓存池没有，再创建。消息使用完了会放回缓存池中,从代码来只有第一次的会创建，然后，把用过的message放回缓存池中  

* 消息缓存池的逻辑  
```
 public static Message obtain() {
        synchronized (sPoolSync) {
            if (sPool != null) {
                Message m = sPool;
                sPool = m.next;
                m.next = null;
                m.flags = 0; // clear in-use flag
                sPoolSize--;
                return m;
            }
        }
        return new Message();
    }  
```

# Hander
```
public Handler(Looper looper, Callback callback, boolean async) {
        mLooper = looper;				
        mQueue = looper.mQueue;
        mCallback = callback;
        mAsynchronous = async;
    }
public static Message obtain(Handler h, Runnable callback) {
        Message m = obtain();
        m.target = h;
        m.callback = callback;
        return m;
    }  

```  
* 当我们调用Handler进行发送消息时，最终都会调用sendMessageAtTime（）方法，最后调用enqueueMessage( ) 发送到消息队列。  

```  
public boolean sendMessageAtTime(Message msg, long uptimeMillis) {
        MessageQueue queue = mQueue;  //获得当前的消息队列
        if (queue == null) {   //若是在创建Handler时没有指定Looper，就不会有对应的消息队列queue ，自然就会为null
            RuntimeException e = new RuntimeException(
                    this + " sendMessageAtTime() called with no mQueue");
            Log.w("Looper", e.getMessage(), e);
            return false;
        }
        return enqueueMessage(queue, msg, uptimeMillis); 
    }

private boolean enqueueMessage(MessageQueue queue, Message msg, long uptimeMillis) {
        msg.target = this;   //这个target就是前面我们说到过的
        if (mAsynchronous) {
            msg.setAsynchronous(true);
        }
        return queue.enqueueMessage(msg, uptimeMillis);
    }  

 public void dispatchMessage(Message msg) {
        if (msg.callback != null) {
            handleCallback(msg);
        } else {
            if (mCallback != null) {
                if (mCallback.handleMessage(msg)) {
                    return;
                }
            }
            handleMessage(msg);
        }
    }

```  
* 如何实现延迟的呢  
  利用的还是epoll机制,epoll_wait这个系统调用，有一个参数是timeout，表示epoll_wait()将要阻塞的毫秒数
* Handler将Message发送到Looper的消息队列中，即MessageQueue，等待Looper的循环读取Message，处理Message，然后调用Message的target，即附属的Handler的dispatchMessage（）方法，将该消息回调到handleMessage（）方法中，然后完成更新UI操作。

# 总结
* 当一个Thread().start()后，就执行传进来的run方法，当然这个Thread是传到native层创建然后调用的run方法，然后在调用外部传进来的runnable。  
  这时如果我们想求让这个Thread loop就要在这个runnable的run中调用looper.prepare(),这里是为了创建一个Looper,并且在这个looper里绑定thread，所以在这里looper是持有thread的。  
  由于looper有个静态变量sThreadLocal（ThreadLocal<Looper>），这个ThreadLocal被当作key，looper当作value存在ThreadLocalMap，ThreadLocalMap是Thread的一个变量threadLocals,ThreadLocalMap内部又个Entry[] table，这个Entry会弱引用ThreadLocal，但不会弱引用value（looper）ThreadLocal是以int i = firstKey.threadLocalHashCode & (INITIAL_CAPACITY - 1);的角标存在table中的table[i] = new Entry(firstKey, firstValue);  

