package com.thoughtworks.DDF.List

import com.thoughtworks.DDF.Arrow.ImpWArrowMin
import com.thoughtworks.DDF.Combinators.Comb
import com.thoughtworks.DDF.Product.{ImpWProduct, ProductRepr}
import com.thoughtworks.DDF.Unit.Unit
import com.thoughtworks.DDF.{ImpW, Loss}

trait ImpWList[Info[_], Repr[_]] extends
  List[Lambda[X => (Info[X], Loss[X])], ImpW[Info, Repr, ?]] with
  ImpWProduct[Info, Repr] {

}

object ImpWList {
  implicit def apply[Info[_], Repr[_]]: ImpWList[Info, Repr] = new ImpWList[Info, Repr] {
    override def listMap[A, B](implicit ai: (Info[A], Loss[A]), bi: (Info[B], Loss[B])): ImpW[Info, Repr, ((A) => B) => (scala.List[A]) => scala.List[B]] = ???

    override def reverse[A](implicit ai: (Info[A], Loss[A])): ImpW[Info, Repr, (scala.List[A]) => scala.List[A]] = ???

    override def foldRight[A, B](implicit ai: (Info[A], Loss[A]), bi: (Info[B], Loss[B])): ImpW[Info, Repr, ((A) => (B) => B) => (B) => (scala.List[A]) => B] = ???

    override def foldLeft[A, B](implicit ai: (Info[A], Loss[A]), bi: (Info[B], Loss[B])): ImpW[Info, Repr, ((A) => (B) => A) => (A) => (scala.List[B]) => A] = ???

    override def listZip[A, B](implicit ai: (Info[A], Loss[A]), bi: (Info[B], Loss[B])): ImpW[Info, Repr, (scala.List[A]) => (scala.List[B]) => scala.List[(A, B)]] = ???

    override def scanLeft[A, B](implicit ai: (Info[A], Loss[A]), bi: (Info[B], Loss[B])): ImpW[Info, Repr, ((B) => (A) => B) => (B) => (scala.List[A]) => scala.List[B]] = ???

    override def scanRight[A, B](implicit ai: (Info[A], Loss[A]), bi: (Info[B], Loss[B])): ImpW[Info, Repr, ((A) => (B) => B) => (B) => (scala.List[A]) => scala.List[B]] = ???

    override implicit def listInfo[A](implicit ai: (Info[A], Loss[A])): (Info[scala.List[A]], Loss[scala.List[A]]) = ???

    override def listElmInfo[A](implicit lai: (Info[scala.List[A]], Loss[scala.List[A]])): (Info[A], Loss[A]) = ???

    override def rp: ProductRepr[Info, Repr] = ???

    override def rcomb: Comb[Info, Repr] = ???

    override def nil[A](implicit ai: (Info[A], Loss[A])): ImpW[Info, Repr, scala.List[A]] = ???

    override def cons[A](implicit ai: (Info[A], Loss[A])): ImpW[Info, Repr, (A) => (scala.List[A]) => scala.List[A]] = ???

    override def listMatch[A, B](implicit ai: (Info[A], Loss[A]), bi: (Info[B], Loss[B])): ImpW[Info, Repr, (scala.List[A]) => (B) => ((A) => (scala.List[A]) => B) => B] = ???

    override def base: ProductRepr[Info, Repr] = ???

    override def runit: Unit[Info, Repr] = ???

  }
}