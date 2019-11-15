---
layout: post
title: HashMap-HashTable
---
# 问：说说 Hashtable 与 HashMap 的区别？  

***答：***这题目可能真的是烂大街的题了，但是既然做系列就有必要被扫荡，这个题就像前面推送的 ArrayList 与 LinkedList 区别、ArrayList 与 Vector 区别等同类。
首先要说 Hashtable 算是一个过时的集合类，因为 JDK1.5 中提供的 ConcurrentHashMap 是 HashTable 的替代品，其扩展性比 HashTable 更好。由于 HashMap 和 Hashtable 都实现了 Map 接口，所以其主要的区别如下：

* HashMap 是非 synchronized 的，而 Hashtable 是 synchronized 的。
* HashMap 可以接受 null 的键和值，而 Hashtable 的 key 与 value 均不能为 null 值。
* HashMap 的迭代器 Iterator 是 fail-fast 机制的，而 Hashtable 的 Enumerator 迭代器不是 fail-fast 机制的（历史原因）。
* 单线程情况下使用 HashMap 性能要比 Hashtable 好，因为 HashMap 是没有同步操作的。
* Hashtable 继承自 Dictionary 类且实现了 Map 接口，而 HashMap 继承自 AbstractMap 类且实现了 Map 接口。
* HashTable 的默认容量为11，而 HashMap 为 16（安卓中为 4）。
* Hashtable 不要求底层数组的容量一定是 2 的整数次幂，而 HashMap 则要求一定为 2 的整数次幂。
* Hashtable 扩容时将容量变为原来的 2 倍加 1，而 HashMap 扩容时将容量变为原来的 2 倍。
* Hashtable 有 contains 方法，而 HashMap 有 containsKey 和 containsValue 方法。

# 问：下面代码段的输出结果是什么？
```
Hashtable<String, String> table = new Hashtable<>();
table.put("name", "yan");
table.put("city", "zhuhai");
System.out.println(table.contains("name"));
System.out.println(table.contains("yan"));
System.out.println(table.containsKey("name"));
System.out.println(table.containsValue("yan"));
```

***答：***输出结果为 false、true、true、true。
一定要切记 Hashtable 的 contains 方法比较的是 value 的 equals 方法且 contains 的参数不能为 null。

# HashMap拉链法导致的链表过深问题为什么不用二叉查找树代替，而选择红黑树？为什么不一直使用红黑树？

***答：***之所以选择红黑树是为了解决二叉查找树的缺陷，二叉查找树在特殊情况下会变成一条线性结构（这就跟原来使用链表结构一样了，造成很深的问题），遍历查找会非常慢。而红黑树在插入新数据后可能需要通过左旋，右旋、变色这些操作来保持平衡，引入红黑树就是为了查找数据快，解决链表查询深度的问题，我们知道红黑树属于平衡二叉树，但是为了保持“平衡”是需要付出代价的，但是该代价所损耗的资源要比遍历线性链表要少，所以当长度大于8的时候，会使用红黑树，如果链表长度很短的话，根本不需要引入红黑树，引入反而会慢。

# 说说你对红黑树的见解？

 <img src="https://github.com/jieqiudede/blog/blob/gh-pages/image/red-black.png?raw=true" with="50%">  
 
* 1.每个节点非红即黑；

* 2.根节点总是黑色的；

* 3.如果节点是红色的，则它的子节点必须是黑色的（反之不一定）；

* 4.每个叶子节点都是黑色的空节点（NIL节点）；

* 5.从根节点到叶节点或空子节点的每条路径，必须包含相同数目的黑色节点（即相同的黑色高度）；

# 我们可以使用CocurrentHashMap来代替Hashtable吗？  
***答：***我们知道 Hashtable 是 synchronized 的，但是 ConcurrentHashMap 同步性能更好，因为它仅仅根据同步级别对 map 的一部分进行上锁。ConcurrentHashMap 当然可以代替 HashTable，但是 HashTable 提供更强的线程安全性。它们都可以用于多线程的环境，但是当 Hashtable 的大小增加到一定的时候，性能会急剧下降，因为迭代时需要被锁定很长的时间。因为 ConcurrentHashMap 引入了分割(segmentation)，不论它变得多么大，仅仅需要锁定 map 的某个部分，而其它的线程不需要等到迭代完成才能访问 map。简而言之，在迭代的过程中，ConcurrentHashMap 仅仅锁定 map 的某个部分，而 Hashtable 则会锁定整个 map。

# CocurrentHashMap（1.7)

* CocurrentHashMap 是由 Segment 数组和 HashEntry 数组和链表组成。

* Segment 是基于重入锁。一个数据段竞争锁，每个 HashEntry 一个链表结构的元素，利用 Hash 算法得到索引确定归属的数据段，也就是对应到在修改时需要竞争获取的锁。ConcurrentHashMap 支持 CurrencyLevel (Segment 数组数量)的线程并发。每当一个线程占用锁访问一个 Segment 时，不会影响到其他的 Segment。

* 核心数据如 value ，以及链表都是 volatile 修饰的，保证了获取时的可见性。

* 首先是通过 key 定位到 Segment，之后在对应的 Segment 中进行具体的 put操作如下。将当前 Segment 中的 table 通过 key 的 hashcode 定位到 HashEntry；遍历该 HashEntry，如果不为空则判断传入的 key 和当前遍历的 key 是否相等，相等则覆盖旧的 value；不为空则需要新建一个 HashEntry 并加入到 Segment 中，同时会先判断是否需要扩容；最后会解除在 1 中所获取当前 Segment 的锁。

* 虽然 HashEntry 中的 value 是用 volatile 关键词修饰的，但是并不能保证并发的原子性，所以 put 操作时仍然需要加锁处理。首先第一步的时候会尝试获取锁，如果获取失败肯定就有其他线程存在竞争，则利用 scanAndLockForPut() 自旋获取锁。尝试自旋获取锁。如果重试的次数达到了 MAX_SCAN_RETRIES 则改为阻塞锁获取，保证能获取成功。最后解除当前 Segment 的锁。 

# CocurrentHashMap（1.8)
* 其中抛弃了原有的 Segment 分段锁，而采用了 CAS + synchronized 来保证并发安全性。

* 其中的 val next 都用了 volatile 修饰，保证了可见性。

* 最大特点是引入了 CAS（借助 Unsafe 来实现【native code】）。对 sizeCtl 的控制都是用 CAS 来实现的；CAS有3个操作数，内存值V，旧的预期值A，要修改的新值B。当且仅当预期值A和内存值V相同时，将内存值V修改为B，否则什么都不做；Unsafe 借助 CPU 指令 cmpxchg 来实现。 

CocurrentHashMap 在 JAVA8 中存在一个 bug，会进入死循环，原因是递归创建 ConcurrentHashMap 对象，但是在 1.9 已经修复了

