package com.thoughtworks.DDF.Bool

import com.thoughtworks.DDF.Arrow.{ArrowLoss, BEvalArrow}
import com.thoughtworks.DDF.Combinators.{BEvalComb, Comb}
import com.thoughtworks.DDF.{BEval, BEvalCase, CommutativeMonoid, CommutativeMonoidUnit, Loss, LossCase, LossInfo}

import scalaz.Leibniz._

trait BEvalBool extends Bool[LossInfo, BEval] with BEvalArrow {
  object BoolBEC extends BEvalCase[Boolean] {
    override type ret = Boolean
  }

  override def litB: Boolean => BEval[Boolean] = b => new BEval[Boolean] {
    override def eca: ec.ret = b

    override def eval: Boolean = b

    override val ec: BEvalCase.Aux[Boolean, Boolean] = BoolBEC

    override val loss: LossInfo[Boolean] = boolInfo
  }

  def beval: BEval[Boolean] => Boolean = x => witness(x.ec.unique(BoolBEC))(x.eca)

  private def comb: Comb[LossInfo, BEval] = BEvalComb.apply

  val bLoss: Loss[Boolean] = new Loss[Boolean] {
    override val li: LossInfo.Aux[Boolean, Unit] = boolInfo

    override val x: li.loss = ()
  }

  override def ite[A](implicit ai: LossInfo[A]): BEval[Boolean => A => A => A] =
    aEval[Boolean, A => A => A](b =>
      (if(beval(b))
        comb.K[A, A](ai, ai) else
        app(comb.C[A, A, A](ai, ai, ai))(comb.K[A, A](ai, ai)), _ => bLoss))(boolInfo, aInfo(ai, aInfo(ai, ai)))

  override implicit def boolInfo: LossInfo.Aux[Boolean, Unit] = new LossInfo[Boolean] {
    override def convert = litB

    override def m: CommutativeMonoid[Unit] = CommutativeMonoidUnit.apply

    override def lca: lc.ret = ()

    override val lc: LossCase.Aux[Boolean, Unit] = new LossCase[Boolean] {
      override type ret = Unit
    }

    override type ret = Unit

    override def update(x: Boolean)(rate: Double)(l: loss): Boolean = x
  }
}

object BEvalBool {
  implicit def apply = new BEvalBool {}
}
