"use client";
import React, { useState } from "react";
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog";
import { Eye, EyeOff } from "lucide-react";

const CORRECT_PASSWORD = "rfce123";

interface PasswordDialogProps {
    open: boolean;
    onClose: () => void;
    onSuccess: () => void;
}

const PasswordDialog = ({ open, onClose, onSuccess }: PasswordDialogProps) => {
    const [password, setPassword] = useState("");
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState("");

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (password === CORRECT_PASSWORD) {
            setPassword("");
            setError("");
            onSuccess();
        } else {
            setError("Incorrect password. Please try again.");
        }
    };

    const handleClose = () => {
        setPassword("");
        setError("");
        onClose();
    };

    return (
        <Dialog open={open} onOpenChange={(v) => !v && handleClose()}>
            <DialogContent className="max-w-sm">
                <DialogHeader>
                    <DialogTitle className="font-syne text-lg font-semibold text-[#101828]">
                        Enter Password
                    </DialogTitle>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4 pt-2">
                    <div className="relative">
                        <input
                            autoFocus
                            type={showPassword ? "text" : "password"}
                            value={password}
                            onChange={(e) => {
                                setPassword(e.target.value);
                                setError("");
                            }}
                            placeholder="Password"
                            className="w-full px-4 py-3 pr-10 outline-none border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-colors text-sm"
                        />
                        <button
                            type="button"
                            onClick={() => setShowPassword((p) => !p)}
                            className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                        >
                            {showPassword ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                        </button>
                    </div>
                    {error && (
                        <p className="text-sm text-red-500">{error}</p>
                    )}
                    <div className="flex gap-2 justify-end">
                        <button
                            type="button"
                            onClick={handleClose}
                            className="px-4 py-2 text-sm font-medium text-gray-600 rounded-lg hover:bg-gray-100 transition-colors"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            className="px-4 py-2 text-sm font-semibold text-white rounded-lg transition-colors"
                            style={{
                                background: "linear-gradient(270deg, #D5CAFC 2.4%, #E3D2EB 27.88%, #F4DCD3 69.23%, #FDE4C2 100%)",
                                color: "#101323",
                            }}
                        >
                            Confirm
                        </button>
                    </div>
                </form>
            </DialogContent>
        </Dialog>
    );
};

export default PasswordDialog;
