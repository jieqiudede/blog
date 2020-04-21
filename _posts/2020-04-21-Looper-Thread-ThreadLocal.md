---
layout: post
title: Looper,ThreadLocal,ThreadLocalMap,MessageQueue
---

# Looper  
* static final ThreadLocal<Looper> sThreadLocal = new ThreadLocal<Looper>();  
'''  

private static void prepare(boolean quitAllowed) {
     if (sThreadLocal.get() != null) {
        throw new RuntimeException("Only one Looper may be created per thread");
     }
     sThreadLocal.set(new Looper(quitAllowed));
     }  

'''  
* final Thread mThread;  
* final MessageQueue mQueue;  

'''  

private Looper(boolean quitAllowed) {
     mQueue = new MessageQueue(quitAllowed);
     mThread = Thread.currentThread();
    }  

'''  

# ThreadLocal  
'''  

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

'''
# ThreadLocalMap  
'''  

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

'''
# MessageQueue  

