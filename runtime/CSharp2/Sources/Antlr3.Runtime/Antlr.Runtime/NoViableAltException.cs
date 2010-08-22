/*
 * [The "BSD licence"]
 * Copyright (c) 2005-2008 Terence Parr
 * All rights reserved.
 *
 * Conversion to C#:
 * Copyright (c) 2008 Sam Harwell, Pixel Mine, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

namespace Antlr.Runtime {
    using ArgumentNullException = System.ArgumentNullException;
    using SerializationInfo = System.Runtime.Serialization.SerializationInfo;
    using StreamingContext = System.Runtime.Serialization.StreamingContext;

    [System.Serializable]
    public class NoViableAltException : RecognitionException {
        private readonly string _grammarDecisionDescription;
        private readonly int _decisionNumber;
        private readonly int _stateNumber;

        public NoViableAltException(string grammarDecisionDescription, int decisionNumber, int stateNumber, IIntStream input)
            : base(input) {
            this._grammarDecisionDescription = grammarDecisionDescription;
            this._decisionNumber = decisionNumber;
            this._stateNumber = stateNumber;
        }

        protected NoViableAltException(SerializationInfo info, StreamingContext context)
            : base(info, context) {
            if (info == null)
                throw new ArgumentNullException("info");

            this._grammarDecisionDescription = info.GetString("GrammarDecisionDescription");
            this._decisionNumber = info.GetInt32("DecisionNumber");
            this._stateNumber = info.GetInt32("StateNumber");
        }

        public int DecisionNumber {
            get {
                return _decisionNumber;
            }
        }

        public string GrammarDecisionDescription {
            get {
                return _grammarDecisionDescription;
            }
        }

        public int StateNumber {
            get {
                return _stateNumber;
            }
        }

        public override void GetObjectData(SerializationInfo info, StreamingContext context) {
            if (info == null)
                throw new ArgumentNullException("info");

            base.GetObjectData(info, context);
            info.AddValue("GrammarDecisionDescription", _grammarDecisionDescription);
            info.AddValue("DecisionNumber", _decisionNumber);
            info.AddValue("StateNumber", _stateNumber);
        }

        public override string ToString() {
            if (Input is ICharStream) {
                return "NoViableAltException('" + (char)UnexpectedType + "'@[" + GrammarDecisionDescription + "])";
            } else {
                return "NoViableAltException(" + UnexpectedType + "@[" + GrammarDecisionDescription + "])";
            }
        }
    }
}
